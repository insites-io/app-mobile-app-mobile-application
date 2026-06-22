import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/api_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/widgets/inline_image_text_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/home_screen.dart';
import 'bloc/cocktail_bloc.dart';
import 'bloc/cocktail_event.dart';
import 'bloc/cocktail_state.dart';
import 'cocktails_list_screen.dart';
import 'data/models/cocktail_model.dart';

class AddCocktailScreen extends StatefulWidget {
  const AddCocktailScreen({super.key, this.cocktail});

  /// When provided, the screen operates in edit mode.
  final Cocktail? cocktail;

  @override
  State<AddCocktailScreen> createState() => _AddCocktailScreenState();
}

class _AddCocktailScreenState extends State<AddCocktailScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  // Markdown-aware controllers: inline `![image](url)` segments render as
  // image thumbnails in the editor instead of raw URL text, while the
  // underlying markdown stays intact for save/load via [getMarkdown].
  final _instructionsController = InlineImageTextController();
  final _ingredientsController = InlineImageTextController();
  final _durationController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> _keywords = [];
  /// Local file shown in the picker preview while the upload is in flight.
  /// Cleared after a successful upload — the rendered preview falls back to
  /// the network URL via [AppImagePicker.existingImageUrl].
  File? _selectedImage;
  /// S3 URL for the hero image after upload completes. Uploading happens at
  /// pick time so the cocktail-save step never has to re-read a temp file
  /// that the OS may have evicted in the meantime.
  String? _selectedImageUrl;
  /// True while the hero-image upload is running. Disables the picker tap
  /// and the Save button so the user can't trigger a save with a partial
  /// state.
  bool _heroUploading = false;

  bool get _isEditing => widget.cocktail != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.cocktail!;
      _nameController.text = c.name;
      // Existing image is already an S3 URL — adopt it as the current
      // hero so we don't re-upload when the user submits without picking
      // a new one.
      _selectedImageUrl = c.image;
      _instructionsController.setMarkdown(c.instructions ?? '');
      _ingredientsController.setMarkdown(c.ingredients ?? '');
      if (c.duration != null) _durationController.text = c.duration.toString();
      if (c.amount != null) _amountController.text = c.amount.toString();
      if (c.keywords != null && c.keywords!.isNotEmpty) {
        _keywords.addAll(
          c.keywords!.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordController.dispose();
    _instructionsController.dispose();
    _ingredientsController.dispose();
    _durationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_heroUploading) return;

    // Grab the api client BEFORE the async gap so we don't reuse a
    // BuildContext that may have been disposed by the time the upload
    // resolves.
    final apiClient = context.read<ApiClient>();
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } catch (_) {
      // Permission denied, plugin error, etc. Fail soft instead of
      // letting the exception crash the screen.
      if (!mounted) return;
      AppToast.show(
        context,
        'Could not access the image. Please check the app permissions.',
        type: AppToastType.error,
      );
      return;
    }
    if (picked == null || !mounted) return;

    // Show the local file in the preview right away while we upload, so
    // the user gets visual feedback. The actual save-time behaviour now
    // relies on the URL we resolve below — not this temp file.
    setState(() {
      _selectedImage = File(picked!.path);
      _heroUploading = true;
    });

    String? url;
    try {
      url = await uploadImageToS3(
        apiClient: apiClient,
        iiaApiKey: ApiConfig.iiaApiKey,
        filePath: picked.path,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _heroUploading = false;
        // Revert the preview — we don't want the user to think the image
        // is committed when the upload actually failed.
        _selectedImage = null;
      });
      AppToast.show(
        context,
        e is ApiException
            ? e.message
            : 'Image upload failed. Please try again.',
        type: AppToastType.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _selectedImageUrl = url;
      // Drop the local file so the picker switches to the network
      // preview keyed by the uploaded URL — that's the source of truth
      // from this point on.
      _selectedImage = null;
      _heroUploading = false;
    });
  }

  /// Pick from Camera or Gallery, upload via the shared S3 helper, and
  /// hand back the public URL for the markdown editor to insert. Returns
  /// null whenever the user cancels OR the upload fails — the editor
  /// treats that as "do nothing", so the markdown stays clean and we
  /// never save an empty placeholder.
  Future<String?> _pickAndUploadInlineImage() async {
    // Grab the ApiClient before any async gap so we don't reuse a
    // BuildContext that may have been disposed by the time the user
    // finishes picking.
    final apiClient = context.read<ApiClient>();
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;

    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return null;
      AppToast.show(
        context,
        'Could not access the image. Please check the app permissions.',
        type: AppToastType.error,
      );
      return null;
    }
    if (picked == null) return null;

    try {
      return await uploadImageToS3(
        apiClient: apiClient,
        iiaApiKey: ApiConfig.iiaApiKey,
        filePath: picked.path,
      );
    } catch (_) {
      if (!mounted) return null;
      AppToast.show(
        context,
        'Image upload failed. Please try again.',
        type: AppToastType.error,
      );
      return null;
    }
  }

  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
        _keywordController.clear();
      });
    }
  }

  void _removeKeyword(String keyword) {
    setState(() => _keywords.remove(keyword));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final keywords = _keywords.isNotEmpty ? _keywords.join(', ') : null;
    final instructionsMd = _instructionsController.getMarkdown().trim();
    final instructions = instructionsMd.isNotEmpty ? instructionsMd : null;
    final ingredientsMd = _ingredientsController.getMarkdown().trim();
    final ingredients = ingredientsMd.isNotEmpty ? ingredientsMd : null;
    final duration = int.tryParse(_durationController.text.trim());
    final amount = int.tryParse(_amountController.text.trim());
    // We upload the hero image at pick time, so this is always a public
    // S3 URL by the time submit runs (or null when the user didn't pick).
    // The repo treats `http(s)://…` values as already-uploaded — see
    // [CocktailRepository.addCocktail].
    final imagePath = _selectedImageUrl;

    if (_isEditing) {
      context.read<CocktailBloc>().add(
            CocktailUpdateRequested(
              id: widget.cocktail!.id!,
              name: name,
              keywords: keywords,
              instructions: instructions,
              ingredients: ingredients,
              duration: duration,
              amount: amount,
              imagePath: imagePath,
            ),
          );
    } else {
      context.read<CocktailBloc>().add(
            CocktailAddRequested(
              name: name,
              keywords: keywords,
              instructions: instructions,
              ingredients: ingredients,
              duration: duration,
              amount: amount,
              imagePath: imagePath,
            ),
          );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _keywordController.clear();
    _instructionsController.clear();
    _ingredientsController.clear();
    _durationController.clear();
    _amountController.clear();
    setState(() {
      _keywords.clear();
      _selectedImage = null;
      _selectedImageUrl = null;
      _heroUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CocktailBloc, CocktailState>(
      listenWhen: (_, current) {
        if (_isEditing) {
          return current is CocktailUpdateSuccess || current is CocktailError;
        }
        return current is CocktailAddSuccess || current is CocktailError;
      },
      listener: (context, state) {
        if (state is CocktailAddSuccess) {
          AppToast.show(context, 'Recipe added successfully!');
          _clearForm();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CocktailsListScreen(),
            ),
          );
        } else if (state is CocktailUpdateSuccess) {
          AppToast.show(context, 'Recipe updated successfully!');
          Navigator.of(context).pop(state.cocktail);
        } else if (state is CocktailError) {
          AppToast.show(context, state.message, type: AppToastType.error);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: Column(
          children: [
            AppHeader(
              title: _isEditing ? 'Edit Recipe' : 'Add Recipe',
              showBackButton: _isEditing,
              showMenuIcon: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name ──
                      AppTextField(
                        label: 'Name',
                        placeholder: 'Name',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Keywords ──
                      AppKeywordsField(
                        controller: _keywordController,
                        keywords: _keywords,
                        onAdd: _addKeyword,
                        onRemove: _removeKeyword,
                      ),
                      const SizedBox(height: 20),

                      // ── Duration & Amount ──
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Duration (min)',
                              placeholder: 'e.g. 10',
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Amount (servings)',
                              placeholder: 'e.g. 2',
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Image ──
                      AppImagePicker(
                        selectedImage: _selectedImage,
                        // After upload completes [_selectedImage] is
                        // cleared and we render the network preview from
                        // [_selectedImageUrl] — which on edit-mode mount
                        // is seeded from the cocktail's existing image.
                        existingImageUrl: _selectedImageUrl,
                        onTap: _pickImage,
                      ),
                      const SizedBox(height: 20),

                      // ── Ingredients ──
                      AppRichTextField(
                        label: 'Ingredients',
                        hintText: 'One ingredient per line',
                        controller: _ingredientsController,
                        onPickImage: _pickAndUploadInlineImage,
                      ),
                      const SizedBox(height: 20),

                      // ── Instructions ──
                      AppRichTextField(
                        hintText: 'Write your instructions here...',
                        controller: _instructionsController,
                        onPickImage: _pickAndUploadInlineImage,
                      ),
                      const SizedBox(height: 32),

                      // ── Buttons ──
                      BlocBuilder<CocktailBloc, CocktailState>(
                        builder: (context, state) {
                          final isLoading = state is CocktailAddInProgress;
                          // Block submit while the hero image is still
                          // uploading — otherwise we'd send a half-built
                          // cocktail with no image URL.
                          final disabled = isLoading || _heroUploading;
                          return Row(
                            children: [
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'CANCEL',
                                  onPressed: disabled
                                      ? null
                                      : _isEditing
                                          ? () => Navigator.of(context).pop()
                                          : () {
                                              _clearForm();
                                              HomeScreen.switchTab(context, 0);
                                            },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppPrimaryButton(
                                  label: _isEditing ? 'UPDATE' : 'SAVE',
                                  isLoading: isLoading || _heroUploading,
                                  onPressed: disabled ? null : _submit,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

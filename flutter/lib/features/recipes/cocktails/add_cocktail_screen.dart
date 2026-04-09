import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/widgets.dart';
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
  final _instructionsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _durationController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> _keywords = [];
  File? _selectedImage;

  bool get _isEditing => widget.cocktail != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.cocktail!;
      _nameController.text = c.name;
      _instructionsController.text = c.instructions ?? '';
      _ingredientsController.text = c.ingredients ?? '';
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
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
    final instructions = _instructionsController.text.trim().isNotEmpty
        ? _instructionsController.text.trim()
        : null;
    final ingredients = _ingredientsController.text.trim().isNotEmpty
        ? _ingredientsController.text.trim()
        : null;
    final duration = int.tryParse(_durationController.text.trim());
    final amount = int.tryParse(_amountController.text.trim());
    final imagePath = _selectedImage?.path;

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe added successfully!')),
          );
          _clearForm();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CocktailsListScreen(),
            ),
          );
        } else if (state is CocktailUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe updated successfully!')),
          );
          Navigator.of(context).pop(state.cocktail);
        } else if (state is CocktailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
                        existingImageUrl:
                            _isEditing ? widget.cocktail!.image : null,
                        onTap: _pickImage,
                      ),
                      const SizedBox(height: 20),

                      // ── Ingredients ──
                      AppRichTextField(
                        label: 'Ingredients',
                        hintText: 'One ingredient per line',
                        controller: _ingredientsController,
                      ),
                      const SizedBox(height: 20),

                      // ── Instructions ──
                      AppRichTextField(
                        hintText: 'Write your instructions here...',
                        controller: _instructionsController,
                      ),
                      const SizedBox(height: 32),

                      // ── Buttons ──
                      BlocBuilder<CocktailBloc, CocktailState>(
                        builder: (context, state) {
                          final isLoading = state is CocktailAddInProgress;
                          return Row(
                            children: [
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'CANCEL',
                                  onPressed: isLoading
                                      ? null
                                      : _isEditing
                                          ? () => Navigator.of(context).pop()
                                          : _clearForm,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppPrimaryButton(
                                  label: _isEditing ? 'UPDATE' : 'SAVE',
                                  isLoading: isLoading,
                                  onPressed: isLoading ? null : _submit,
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

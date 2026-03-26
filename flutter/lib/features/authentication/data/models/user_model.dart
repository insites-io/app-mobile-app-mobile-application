/// Contact information associated with a user's company.
///
/// Note: The `id` field is only present in the login response, not in `/me`.
class Contact {
  const Contact({
    this.id,
    this.companyUuid,
    this.mobilePhoneNumber,
    this.mobilePhoneCountryCode,
    this.companyName,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String?,
      companyUuid: json['company_uuid'] as String?,
      mobilePhoneNumber: json['mobile_phone_number'] as String?,
      mobilePhoneCountryCode: json['mobile_phone_country_code'] as String?,
      companyName: json['company_name'] as String?,
    );
  }

  final String? id;
  final String? companyUuid;
  final String? mobilePhoneNumber;
  final String? mobilePhoneCountryCode;
  final String? companyName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_uuid': companyUuid,
        'mobile_phone_number': mobilePhoneNumber,
        'mobile_phone_country_code': mobilePhoneCountryCode,
        'company_name': companyName,
      };
}

/// Authenticated user returned by the IIA login and /me endpoints.
class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.externalId,
    this.permissionLevel,
    this.primaryAccountHolder = false,
    this.profilePictureUrl,
    this.contact,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      externalId: json['external_id'] as String?,
      permissionLevel: json['permission_level'] as String?,
      primaryAccountHolder: json['primary_account_holder'] as bool? ?? false,
      profilePictureUrl: json['profile_picture_url'] as String?,
      contact: json['contact'] != null
          ? Contact.fromJson(json['contact'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? externalId;
  final String? permissionLevel;
  final bool primaryAccountHolder;
  final String? profilePictureUrl;
  final Contact? contact;

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'external_id': externalId,
        'permission_level': permissionLevel,
        'primary_account_holder': primaryAccountHolder,
        'profile_picture_url': profilePictureUrl,
        'contact': contact?.toJson(),
      };
}

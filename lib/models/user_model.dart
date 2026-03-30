class UserModel {
  final int userId;
  final int userType; // 1=儿童, 2=家长
  final int? parentId;
  final String? nickname;
  final String? avatar;
  final String? phone;
  final int? age;
  final int? gender;
  final int? grade;
  final int starCount;
  final int status;

  const UserModel({
    required this.userId,
    required this.userType,
    this.parentId,
    this.nickname,
    this.avatar,
    this.phone,
    this.age,
    this.gender,
    this.grade,
    this.starCount = 0,
    this.status = 1,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int? ?? 0,
      userType: json['userType'] as int? ?? 1,
      parentId: json['parentId'] as int?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as int?,
      grade: json['grade'] as int?,
      starCount: json['starCount'] as int? ?? 0,
      status: json['status'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
      if (parentId != null) 'parentId': parentId,
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (phone != null) 'phone': phone,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (grade != null) 'grade': grade,
      'starCount': starCount,
      'status': status,
    };
  }

  UserModel copyWith({
    int? userId,
    int? userType,
    int? parentId,
    String? nickname,
    String? avatar,
    String? phone,
    int? age,
    int? gender,
    int? grade,
    int? starCount,
    int? status,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      parentId: parentId ?? this.parentId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      grade: grade ?? this.grade,
      starCount: starCount ?? this.starCount,
      status: status ?? this.status,
    );
  }
}

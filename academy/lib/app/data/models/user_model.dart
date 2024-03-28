class UserModel {
  String? name;
  String? email;
  String? token;

  UserModel({this.name, this.email, this.token});

  UserModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['email'] = email;
    data['token'] = token;
    return data;
  }
}

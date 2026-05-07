/// Input validators
class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    return phoneRegex.hasMatch(phone);
  }
}

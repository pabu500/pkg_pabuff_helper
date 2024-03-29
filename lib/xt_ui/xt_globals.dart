// This file contains all the global variables and constants used in the app
const int maxLoginNameLength = 30;
const int maxFullNameLength = 50;
const int maxEmailLength = 250;
const int maxPhoneLength = 20;
const int maxPasswordLength = 30;
const int minPasswordLength = 8;

const String glb_reg_allkeyboard =
    r"^[a-zA-Z0-9!@#\$%^&*()_+\-=\[\]{};':\\|,.<>\/?\s]+$";

// ^ matches the start of the string
// [a-zA-Z]{2,} matches 2 or more consecutive letters (lowercase or uppercase)
// [a-zA-Z\s]* matches zero or more consecutive letters (lowercase or uppercase) or whitespace characters
// [a-zA-Z]{2,}$ matches 2 or more consecutive letters (lowercase or uppercase) and matches the end of the string
// const String glb_reg_fullName = r"^[a-zA-Z]{2,}[a-zA-Z\s]*[a-zA-Z]{2,}$";
const String glb_reg_fullName = r"^[a-zA-Z]{2,}([a-zA-Z\s\-]*[a-zA-Z])?$";
const String glb_fullName_callout = 'Please provide a valid full name';
const String glb_regNG_fullName = r"[^a-zA-Z '\.]|([.']| )(\.|')|(\s)(\s)";
// r"^
// [a-zA-Z0-9-]  //mmatches any character from the alphabet (lowercase or uppercase), digits, or the hyphen symbol
// {6,} //matches the preceding expression (a character from the alphabet or a hyphen symbol) at least 6 times
// $
const String glb_reg_loginName = r"^[a-zA-Z0-9-]{4,}$";
const String glb_loginName_callout =
    'Please provide a valid username (alphabets, numbers and - only, at least 4 characters)';
const String glb_regNG_loginName = r"[^a-zA-Z0-9-]+";

// const String glb_reg_email = r"^[a-zA-Z0-9.-]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
const String glb_reg_email =
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";

const String glb_email_callout = 'Please provide a valid email address';
const String glb_regNG_email = r"[^a-zA-Z0-9@. ]+|([@\.])([@\.])";

/* for test https://regex101.com/
95687951
6595687951
+6595687951
+65 95687951
+8613851610359
+86 13851610359
+60 1223568874
*/
const String glb_reg_phone = r"^\+?[0-9]{0,3}[\s]*[0-9]{0,3}[\s]*[0-9]{8,13}$";
const String glb_phone_callout = 'Please provide a valid phone number';
const String glb_regNG_phone = r"[^0-9+ ]|([0-9+ ])([+])|(\s)(\s)";

// r'^
//   (?=.*[A-Z])       // should contain at least one upper case
//   (?=.*[a-z])       // should contain at least one lower case
//   (?=.*?[0-9])      // should contain at least one digit
//   (?=.*?[!@#\$&*~]) // should contain at least one Special character
//   .{8,}             // Must be at least 8 characters in length
// $
const String glb_reg_password =
    r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.{8,}$)";
const String glb_password_callout =
    'Please provide a valid password (at least 8 characters, at lease 1 upper case, 1 lower case and 1 digit)';
const String glb_regNG_password = r"[^a-zA-Z0-9!@#\$&*~]+";

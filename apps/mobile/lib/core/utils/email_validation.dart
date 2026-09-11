/// Local syntax check only; Supabase remains authoritative for account validity.
bool isValidEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

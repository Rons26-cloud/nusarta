-- ============================================================
-- NUSARTA — Default categories for new users
-- Called from the Flutter app after signup, or manually executed.
-- Idempotent: safe to run more than once.
-- ============================================================

create or replace function public.seed_default_categories(p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.categories (user_id, name, kind, icon, color, is_default) values
    (p_user_id, 'Salary',          'income',  'salary',     '#0B6E4F', true),
    (p_user_id, 'Business',        'income',  'briefcase',  '#10A474', true),
    (p_user_id, 'Gift',            'income',  'gift',       '#C7A24A', true),
    (p_user_id, 'Other Income',    'income',  'plus',       '#5A6B66', true),
    (p_user_id, 'Food & Dining',   'expense', 'restaurant', '#C0392B', true),
    (p_user_id, 'Transport',       'expense', 'car',        '#2980B9', true),
    (p_user_id, 'Shopping',        'expense', 'bag',        '#8E44AD', true),
    (p_user_id, 'Utilities',       'expense', 'zap',        '#F39C12', true),
    (p_user_id, 'Housing & Rent',  'expense', 'home',       '#0B6E4F', true),
    (p_user_id, 'Health',          'expense', 'heart',      '#E74C3C', true),
    (p_user_id, 'Education',       'expense', 'book',       '#16A085', true),
    (p_user_id, 'Entertainment',   'expense', 'film',       '#9B59B6', true),
    (p_user_id, 'Travel',          'expense', 'plane',      '#3498DB', true),
    (p_user_id, 'Subscriptions',   'expense', 'repeat',     '#95A5A6', true),
    (p_user_id, 'Insurance',       'expense', 'shield',     '#7F8C8D', true),
    (p_user_id, 'Other Expense',   'expense', 'ellipsis',   '#5A6B66', true)
  on conflict do nothing;
end $$;
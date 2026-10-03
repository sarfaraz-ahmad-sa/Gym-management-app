import 'package:flutter/material.dart';

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.required = false,
    this.type = 'text',
    this.options = const [],
    this.reference,
    this.defaultValue,
    this.hint,
  });
  final String key, label, type;
  final bool required;
  final List<String> options;
  final String? reference, hint;
  final Object? defaultValue;
}

class EntitySpec {
  const EntitySpec(
    this.table,
    this.title,
    this.singular,
    this.subtitle,
    this.icon,
    this.fields,
    this.columns,
  );
  final String table, title, singular, subtitle;
  final IconData icon;
  final List<FieldSpec> fields;
  final List<String> columns;
}

const entities = {
  'members': EntitySpec(
    'members',
    'Members',
    'member',
    'Know your members. Support their next milestone.',
    Icons.people_outline_rounded,
    [
      FieldSpec('name', 'Full name', required: true),
      FieldSpec(
        'phone',
        'Phone number',
        required: true,
        type: 'phone',
        hint: '+92 300 1234567',
      ),
      FieldSpec('email', 'Email address', type: 'email'),
      FieldSpec(
        'plan_id',
        'Membership plan',
        type: 'reference',
        reference: 'membership_plans',
      ),
      FieldSpec(
        'trainer_id',
        'Assigned trainer',
        type: 'reference',
        reference: 'trainers',
      ),
      FieldSpec('join_date', 'Joined on', type: 'date', required: true),
      FieldSpec('expiry_date', 'Membership ends', type: 'date'),
      FieldSpec(
        'status',
        'Status',
        type: 'select',
        options: ['active', 'inactive', 'suspended'],
        defaultValue: 'active',
      ),
      FieldSpec('goal', 'Fitness goal'),
      FieldSpec('address', 'Address', type: 'multiline'),
    ],
    ['name', 'plan_id', 'expiry_date', 'status'],
  ),
  'membership_plans': EntitySpec(
    'membership_plans',
    'Memberships',
    'plan',
    'Flexible memberships for every kind of athlete.',
    Icons.workspace_premium_outlined,
    [
      FieldSpec('name', 'Plan name', required: true),
      FieldSpec('price', 'Price', required: true, type: 'money'),
      FieldSpec(
        'duration_days',
        'Duration in days',
        required: true,
        type: 'positive',
        defaultValue: 30,
      ),
      FieldSpec('description', 'Description', type: 'multiline'),
      FieldSpec(
        'features',
        'Benefits (separate with commas)',
        type: 'multiline',
      ),
    ],
    ['name', 'price', 'duration_days', 'features'],
  ),
  'trainers': EntitySpec(
    'trainers',
    'Trainers',
    'trainer',
    'A stronger team behind every stronger member.',
    Icons.sports_gymnastics_rounded,
    [
      FieldSpec('name', 'Full name', required: true),
      FieldSpec('phone', 'Phone number', required: true, type: 'phone'),
      FieldSpec('email', 'Email address', type: 'email'),
      FieldSpec('specialization', 'Specialization', required: true),
      FieldSpec('hire_date', 'Joined on', type: 'date'),
      FieldSpec(
        'status',
        'Status',
        type: 'select',
        options: ['active', 'inactive'],
        defaultValue: 'active',
      ),
    ],
    ['name', 'specialization', 'phone', 'status'],
  ),
  'fee_invoices': EntitySpec(
    'fee_invoices',
    'Fee invoices',
    'invoice',
    'Track monthly fees and partial receipts.',
    Icons.receipt_long_outlined,
    [
      FieldSpec(
        'member_id',
        'Member',
        required: true,
        type: 'reference',
        reference: 'members',
      ),
      FieldSpec('amount', 'Billed amount', required: true, type: 'money'),
      FieldSpec('due_date', 'Due date', required: true, type: 'date'),
      FieldSpec('period', 'Fee month (YYYY-MM)', hint: '2026-10'),
      FieldSpec('description', 'Description', type: 'multiline'),
      FieldSpec(
        'status',
        'Status',
        type: 'select',
        options: ['unpaid', 'void'],
        defaultValue: 'unpaid',
      ),
    ],
    ['member_id', 'amount', 'due_date', 'status'],
  ),
  'payments': EntitySpec(
    'payments',
    'Payments',
    'payment',
    'Every receipt, renewal and outstanding balance in one place.',
    Icons.account_balance_wallet_outlined,
    [
      FieldSpec(
        'member_id',
        'Member',
        required: true,
        type: 'reference',
        reference: 'members',
      ),
      FieldSpec(
        'plan_id',
        'Membership plan',
        type: 'reference',
        reference: 'membership_plans',
      ),
      FieldSpec(
        'invoice_id',
        'Fee invoice (optional)',
        type: 'reference',
        reference: 'fee_invoices',
      ),
      FieldSpec('amount', 'Amount', required: true, type: 'money'),
      FieldSpec('payment_date', 'Payment date', required: true, type: 'date'),
      FieldSpec(
        'status',
        'Status',
        type: 'select',
        options: ['completed', 'pending', 'failed'],
        defaultValue: 'completed',
      ),
      FieldSpec(
        'payment_method',
        'Payment method',
        type: 'select',
        options: ['cash', 'card', 'bank_transfer'],
        defaultValue: 'cash',
      ),
      FieldSpec('transaction_id', 'Reference / receipt number'),
    ],
    ['member_id', 'amount', 'payment_date', 'status'],
  ),
  'inventory_items': EntitySpec(
    'inventory_items',
    'Equipment',
    'equipment',
    'Keep your gym floor ready for every workout.',
    Icons.fitness_center_rounded,
    [
      FieldSpec('name', 'Equipment name', required: true),
      FieldSpec(
        'category',
        'Category',
        type: 'select',
        options: ['strength', 'cardio', 'accessories', 'other'],
        defaultValue: 'strength',
      ),
      FieldSpec(
        'quantity',
        'Quantity',
        required: true,
        type: 'integer',
        defaultValue: 1,
      ),
      FieldSpec(
        'condition',
        'Condition',
        type: 'select',
        options: ['good', 'fair', 'poor', 'maintenance'],
        defaultValue: 'good',
      ),
      FieldSpec('purchase_price', 'Purchase price', type: 'money'),
      FieldSpec('purchase_date', 'Purchased on', type: 'date'),
      FieldSpec('notes', 'Maintenance notes', type: 'multiline'),
    ],
    ['name', 'category', 'quantity', 'condition'],
  ),
  'workout_plans': EntitySpec(
    'workout_plans',
    'Workouts',
    'workout',
    'Purposeful programs. Clear goals. Better progress.',
    Icons.auto_awesome_outlined,
    [
      FieldSpec('name', 'Program name', required: true),
      FieldSpec(
        'level',
        'Level',
        type: 'select',
        options: ['beginner', 'intermediate', 'advanced'],
        defaultValue: 'beginner',
      ),
      FieldSpec(
        'duration_weeks',
        'Duration in weeks',
        required: true,
        type: 'positive',
        defaultValue: 4,
      ),
      FieldSpec(
        'description',
        'Exercises and coaching notes',
        required: true,
        type: 'multiline',
      ),
    ],
    ['name', 'level', 'duration_weeks', 'description'],
  ),
};

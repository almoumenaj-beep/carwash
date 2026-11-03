import 'package:carwash_app/features/equipment/domain/equipment.dart';
import 'package:carwash_app/features/equipment/presentation/equipment_forms.dart';
import 'package:carwash_app/features/expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads equipment that is overdue for maintenance', () {
    final equipment = Equipment.fromJson({
      'id': 'e1',
      'branch': {'id': 'b1', 'name': 'Main'},
      'name': 'Pressure washer 1',
      'serial_number': 'K-123',
      'purchased_on': '2026-10-01',
      'purchase_cost': 450000,
      'status': 'out_of_service',
      'maintenance_interval_days': 30,
      'last_maintained_on': null,
      'next_maintenance_on': '2026-10-31',
      'days_until_maintenance': -3,
      'is_due': true,
      'notes': null,
    });

    expect(equipment.status, EquipmentStatus.outOfService);
    expect(equipment.branchName, 'Main');
    expect(equipment.nextMaintenanceOn, DateTime(2026, 10, 31));
    expect(equipment.daysUntilMaintenance, -3);
    expect(equipment.isDue, isTrue);
  });

  test('reads maintenance owed to a supplier', () {
    final maintenance = Maintenance.fromJson({
      'id': 'm1',
      'kind': 'repair',
      'performed_on': '2026-11-02',
      'description': 'New pump',
      'cost': 15000,
      'supplier': {'id': 's1', 'name': 'Kärcher service'},
      'is_paid': false,
      'created_by': {'id': 'u1', 'name': 'Ali'},
    });

    expect(maintenance.kind, MaintenanceKind.repair);
    expect(maintenance.supplierName, 'Kärcher service');
    expect(maintenance.isPaid, isFalse);
  });

  test('records maintenance under the maintenance category when there is one', () {
    const rent = ExpenseCategory(id: 'c1', name: 'إيجار', isActive: true);
    const maintenance = ExpenseCategory(id: 'c2', name: 'صيانة ومعدات', isActive: true);

    expect(maintenanceCategory([rent, maintenance])?.id, 'c2');
    expect(maintenanceCategory([rent])?.id, 'c1');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:medreminder/models/medication.dart';

void main() {
  group('Medication模型测试', () {
    test('Medication.fromMap 正确解析数据', () {
      final map = {
        'id': 'test-id-1',
        'name': '维生素C',
        'category': 'supplement',
        'dosage': '1片',
        'usage': '每日1次',
        'schedule': '{"type":"daily","times":["08:00"]}',
        'is_active': 1,
        'plan_group_id': null,
        'created_at': '2026-03-10 10:00:00',
        'updated_at': '2026-03-10 10:00:00',
      };

      final medication = Medication.fromMap(map);

      expect(medication.id, 'test-id-1');
      expect(medication.name, '维生素C');
      expect(medication.category, MedicationCategory.supplement);
      expect(medication.dosage, '1片');
      expect(medication.isActive, true);
    });

    test('Medication.toMap 正确序列化为Map', () {
      final medication = Medication(
        id: 'test-id-2',
        name: '阿莫西林',
        category: MedicationCategory.medicine,
        dosage: '500mg',
        usage: '每日3次',
        schedule: Schedule(
          type: ScheduleType.daily,
          times: ['08:00', '14:00', '20:00'],
        ),
        isActive: true,
        createdAt: DateTime(2026, 3, 10),
        updatedAt: DateTime(2026, 3, 10),
      );

      final map = medication.toMap();

      expect(map['id'], 'test-id-2');
      expect(map['name'], '阿莫西林');
      expect(map['category'], 'medicine');
      expect(map['is_active'], 1);
    });

    test('Schedule.toJson 正确生成JSON', () {
      final schedule = Schedule(
        type: ScheduleType.daily,
        times: ['08:00', '20:00'],
      );

      final json = schedule.toJson();

      expect(json.contains('"type":"daily"'), true);
      expect(json.contains('"times":["08:00","20:00"]'), true);
    });

    test('Schedule.fromJson 正确解析JSON', () {
      const json = '{"type":"daily","times":["08:00","20:00"]}';

      final schedule = Schedule.fromJson(json);

      expect(schedule.type, ScheduleType.daily);
      expect(schedule.times.length, 2);
      expect(schedule.times[0], '08:00');
    });

    test('多天计划 daysCount 参数正确', () {
      final schedule = Schedule(
        type: ScheduleType.multiday,
        times: ['08:00'],
        startDate: DateTime(2026, 3, 10),
        daysCount: 7,
      );

      // 验证多天计划的天数
      expect(schedule.daysCount, 7);
      expect(schedule.type, ScheduleType.multiday);
    });
  });

  group('Record模型测试', () {
    test('Record.fromMap 正确解析数据', () {
      final map = {
        'id': 'record-1',
        'medication_id': 'med-1',
        'scheduled_time': '2026-03-10 08:00:00',
        'actual_time': '2026-03-10 08:05:00',
        'status': 'taken',
        'skip_reason': null,
        'created_at': '2026-03-10 08:00:00',
      };

      final record = Record.fromMap(map);

      expect(record.id, 'record-1');
      expect(record.medicationId, 'med-1');
      expect(record.status, RecordStatus.taken);
    });

    test('Record.toMap 正确序列化为Map', () {
      final record = Record(
        id: 'record-2',
        medicationId: 'med-2',
        scheduledTime: DateTime(2026, 3, 10, 8, 0),
        actualTime: DateTime(2026, 3, 10, 8, 10),
        status: RecordStatus.taken,
        createdAt: DateTime(2026, 3, 10, 8, 0),
      );

      final map = record.toMap();

      expect(map['id'], 'record-2');
      expect(map['status'], 'taken');
    });
  });
}

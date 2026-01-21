import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../features/merit/data/models/merit_record_model.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/booking/data/models/booking_model.dart';
import '../features/referee/data/models/referee_job_model.dart';

/// Merit service for MyMerit academic integration (GP08)
class MeritService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  MeritService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // MERIT POINTS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if merit has already been awarded for this activity
  Future<bool> _hasAlreadyAwarded({
    required String referenceId,
    required MeritActivityType activityType,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.meritRecordsCollection)
          .where('userId', isEqualTo: userId)
          .where('referenceId', isEqualTo: referenceId)
          .where('activityType', isEqualTo: activityType.code)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // If check fails, allow awarding (better to award than block)
      return false;
    }
  }

  /// Check if user has reached semester cap
  Future<bool> _checkSemesterCap({
    required String userId,
    required int pointsToAdd,
  }) async {
    try {
      final semester = _getCurrentSemester();
      final academicYear = _getCurrentAcademicYear();

      final records = await getMeritRecordsBySemester(
        userId: userId,
        semester: semester,
        academicYear: academicYear,
      );

      final currentPoints = records.fold<int>(0, (total, r) => total + r.points);
      final newTotal = currentPoints + pointsToAdd;

      return newTotal <= AppConstants.meritPointsMaxPerSemester;
    } catch (e) {
      // If check fails, allow awarding (better to award than block)
      return true;
    }
  }

  /// Award merit points for player participation
  Future<MeritResult> awardPlayerMerit({
    required UserModel user,
    required BookingModel booking,
  }) async {
    // Only students can earn merit
    if (!user.isStudent) {
      return MeritResult.failure('Only UPM students can earn merit points');
    }

    // Check if already awarded
    final alreadyAwarded = await _hasAlreadyAwarded(
      referenceId: booking.id,
      activityType: MeritActivityType.playerParticipation,
      userId: user.uid,
    );

    if (alreadyAwarded) {
      return MeritResult.failure('Merit already awarded for this booking');
    }

    // Check semester cap
    final capOk = await _checkSemesterCap(
      userId: user.uid,
      pointsToAdd: AppConstants.meritPointsPlayer,
    );

    if (!capOk) {
      return MeritResult.failure(
        'Semester cap reached (${AppConstants.meritPointsMaxPerSemester} points). Cannot award more points this semester.',
      );
    }

    try {
      final meritId = _uuid.v4();
      final semester = _getCurrentSemester();
      final academicYear = _getCurrentAcademicYear();

      final record = MeritRecordModel(
        id: meritId,
        oderId: _uuid.v4(),
        userId: user.uid,
        userEmail: user.email,
        userName: user.displayName,
        matricNo: user.matricNo,
        category: MeritCategory.sports,
        activityType: MeritActivityType.playerParticipation,
        sport: booking.sport,
        activityDescription: MeritRecordModel.generateDescription(
          MeritActivityType.playerParticipation,
          booking.sport,
          booking.facilityName,
        ),
        points: AppConstants.meritPointsPlayer,
        gp08Code: AppConstants.meritCodePlayer, // B1
        referenceId: booking.id,
        activityDate: booking.startTime,
        semester: semester,
        academicYear: academicYear,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.meritRecordsCollection)
          .doc(meritId)
          .set(record.toFirestore());

      // Update user's total merit points
      await _updateUserMeritPoints(user.uid, AppConstants.meritPointsPlayer);

      return MeritResult.success(record);
    } catch (e) {
      return MeritResult.failure('Failed to award merit: ${e.toString()}');
    }
  }

  /// Award merit points for referee service
  Future<MeritResult> awardRefereeMerit({
    required UserModel user,
    required RefereeJobModel job,
  }) async {
    if (!user.isStudent) {
      return MeritResult.failure('Only UPM students can earn merit points');
    }

    // Check if already awarded
    final alreadyAwarded = await _hasAlreadyAwarded(
      referenceId: job.id,
      activityType: MeritActivityType.refereeService,
      userId: user.uid,
    );

    if (alreadyAwarded) {
      return MeritResult.failure('Merit already awarded for this referee job');
    }

    // Check semester cap
    final capOk = await _checkSemesterCap(
      userId: user.uid,
      pointsToAdd: AppConstants.meritPointsReferee,
    );

    if (!capOk) {
      return MeritResult.failure(
        'Semester cap reached (${AppConstants.meritPointsMaxPerSemester} points). Cannot award more points this semester.',
      );
    }

    try {
      final meritId = _uuid.v4();
      final semester = _getCurrentSemester();
      final academicYear = _getCurrentAcademicYear();

      final record = MeritRecordModel(
        id: meritId,
        oderId: _uuid.v4(),
        userId: user.uid,
        userEmail: user.email,
        userName: user.displayName,
        matricNo: user.matricNo,
        category: MeritCategory.leadership, // Referee counts as leadership (B2)
        activityType: MeritActivityType.refereeService,
        sport: job.sport,
        activityDescription: MeritRecordModel.generateDescription(
          MeritActivityType.refereeService,
          job.sport,
          job.facilityName,
        ),
        points: AppConstants.meritPointsReferee,
        gp08Code: AppConstants.meritCodeReferee, // B2
        referenceId: job.id,
        activityDate: job.startTime,
        semester: semester,
        academicYear: academicYear,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.meritRecordsCollection)
          .doc(meritId)
          .set(record.toFirestore());

      await _updateUserMeritPoints(user.uid, AppConstants.meritPointsReferee);

      return MeritResult.success(record);
    } catch (e) {
      return MeritResult.failure('Failed to award merit: ${e.toString()}');
    }
  }

  /// Award merit points for tournament organizer
  Future<MeritResult> awardOrganizerMerit({
    required UserModel user,
    required String tournamentId,
    required SportType sport,
    required String facilityName,
    required DateTime tournamentDate,
  }) async {
    // Only students can earn merit
    if (!user.isStudent) {
      return MeritResult.failure('Only UPM students can earn merit points');
    }

    // Check if already awarded
    final alreadyAwarded = await _hasAlreadyAwarded(
      referenceId: tournamentId,
      activityType: MeritActivityType.sukolOrganizer,
      userId: user.uid,
    );

    if (alreadyAwarded) {
      return MeritResult.failure('Merit already awarded for this tournament');
    }

    // Check semester cap
    final capOk = await _checkSemesterCap(
      userId: user.uid,
      pointsToAdd: AppConstants.meritPointsOrganizer,
    );

    if (!capOk) {
      return MeritResult.failure(
        'Semester cap reached (${AppConstants.meritPointsMaxPerSemester} points). Cannot award more points this semester.',
      );
    }

    try {
      final meritId = _uuid.v4();
      final semester = _getCurrentSemester();
      final academicYear = _getCurrentAcademicYear();

      final record = MeritRecordModel(
        id: meritId,
        oderId: _uuid.v4(),
        userId: user.uid,
        userEmail: user.email,
        userName: user.displayName,
        matricNo: user.matricNo,
        category: MeritCategory.leadership, // Tournament organizer counts as leadership (B3)
        activityType: MeritActivityType.sukolOrganizer,
        sport: sport,
        activityDescription: MeritRecordModel.generateDescription(
          MeritActivityType.sukolOrganizer,
          sport,
          facilityName,
        ),
        points: AppConstants.meritPointsOrganizer,
        gp08Code: AppConstants.meritCodeOrganizer, // B3
        referenceId: tournamentId,
        activityDate: tournamentDate,
        semester: semester,
        academicYear: academicYear,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.meritRecordsCollection)
          .doc(meritId)
          .set(record.toFirestore());

      await _updateUserMeritPoints(user.uid, AppConstants.meritPointsOrganizer);

      return MeritResult.success(record);
    } catch (e) {
      return MeritResult.failure('Failed to award merit: ${e.toString()}');
    }
  }

  /// Award merit points for tournament participant
  Future<MeritResult> awardParticipantMerit({
    required UserModel user,
    required String tournamentId,
    required SportType sport,
    required String facilityName,
    required DateTime tournamentDate,
  }) async {
    // Only students can earn merit
    if (!user.isStudent) {
      return MeritResult.failure('Only UPM students can earn merit points');
    }

    // Check if already awarded
    final alreadyAwarded = await _hasAlreadyAwarded(
      referenceId: tournamentId,
      activityType: MeritActivityType.sukolParticipant,
      userId: user.uid,
    );

    if (alreadyAwarded) {
      return MeritResult.failure('Merit already awarded for this tournament participation');
    }

    // Check semester cap
    final capOk = await _checkSemesterCap(
      userId: user.uid,
      pointsToAdd: AppConstants.meritPointsPlayer, // B1: +2 points
    );

    if (!capOk) {
      return MeritResult.failure(
        'Semester cap reached (${AppConstants.meritPointsMaxPerSemester} points). Cannot award more points this semester.',
      );
    }

    try {
      final meritId = _uuid.v4();
      final semester = _getCurrentSemester();
      final academicYear = _getCurrentAcademicYear();

      final record = MeritRecordModel(
        id: meritId,
        oderId: _uuid.v4(),
        userId: user.uid,
        userEmail: user.email,
        userName: user.displayName,
        matricNo: user.matricNo,
        category: MeritCategory.sports,
        activityType: MeritActivityType.sukolParticipant,
        sport: sport,
        activityDescription: MeritRecordModel.generateDescription(
          MeritActivityType.sukolParticipant,
          sport,
          facilityName,
        ),
        points: AppConstants.meritPointsPlayer, // B1: +2 points
        gp08Code: AppConstants.meritCodePlayer, // B1
        referenceId: tournamentId,
        activityDate: tournamentDate,
        semester: semester,
        academicYear: academicYear,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.meritRecordsCollection)
          .doc(meritId)
          .set(record.toFirestore());

      await _updateUserMeritPoints(user.uid, AppConstants.meritPointsPlayer);

      return MeritResult.success(record);
    } catch (e) {
      return MeritResult.failure('Failed to award merit: ${e.toString()}');
    }
  }

  /// Update user's total merit points
  Future<void> _updateUserMeritPoints(String userId, int points) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'totalMeritPoints': FieldValue.increment(points),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MERIT RECORDS RETRIEVAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all merit records for a user
  Future<List<MeritRecordModel>> getUserMeritRecords(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.meritRecordsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('activityDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MeritRecordModel.fromFirestore(doc))
        .toList();
  }

  /// Get merit records by semester
  Future<List<MeritRecordModel>> getMeritRecordsBySemester({
    required String userId,
    required String semester,
    required String academicYear,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.meritRecordsCollection)
        .where('userId', isEqualTo: userId)
        .where('semester', isEqualTo: semester)
        .where('academicYear', isEqualTo: academicYear)
        .orderBy('activityDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MeritRecordModel.fromFirestore(doc))
        .toList();
  }

  /// Get merit summary by category
  Future<Map<MeritCategory, int>> getMeritSummary(String userId) async {
    final records = await getUserMeritRecords(userId);

    final summary = <MeritCategory, int>{};
    for (final category in MeritCategory.values) {
      summary[category] = records
          .where((r) => r.category == category)
          .fold(0, (total, r) => total + r.points);
    }

    return summary;
  }

  /// Get total merit points for user
  Future<int> getTotalMeritPoints(String userId) async {
    final records = await getUserMeritRecords(userId);
    return records.fold<int>(0, (total, r) => total + r.points);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF TRANSCRIPT GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate PDF transcript of merit records
  Future<pw.Document> generateMeritTranscript({
    required UserModel user,
    String? semester,
    String? academicYear,
  }) async {
    // Get merit records
    List<MeritRecordModel> records;
    if (semester != null && academicYear != null) {
      records = await getMeritRecordsBySemester(
        userId: user.uid,
        semester: semester,
        academicYear: academicYear,
      );
    } else {
      records = await getUserMeritRecords(user.uid);
    }

    final totalPoints = records.fold(0, (total, r) => total + r.points);
    final dateFormat = DateFormat('dd MMM yyyy');

    // Create PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(user),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text(
              'MERIT ACTIVITY TRANSCRIPT',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'PutraSportHub - UPM Housing Merit System (GP08)',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 24),

          // Student Info
          _buildStudentInfo(user, semester, academicYear),
          pw.SizedBox(height: 24),

          // Summary
          _buildMeritSummary(records, totalPoints),
          pw.SizedBox(height: 24),

          // Activity Table
          pw.Text(
            'ACTIVITY DETAILS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildActivityTable(records, dateFormat),
          pw.SizedBox(height: 24),

          // Verification
          _buildVerificationSection(),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(UserModel user) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.green800),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'UNIVERSITI PUTRA MALAYSIA',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text(
                'Pusat Sukan',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green800),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'PSH-${user.uid.substring(0, 8).toUpperCase()}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStudentInfo(
    UserModel user,
    String? semester,
    String? academicYear,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('Name', user.displayName),
                _infoRow('Email', user.email),
                _infoRow('Matric No.', user.matricNo ?? 'N/A'),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('Semester', semester ?? 'All'),
                _infoRow('Academic Year', academicYear ?? 'All'),
                _infoRow('Status', user.isStudent ? 'Student' : 'Public'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMeritSummary(List<MeritRecordModel> records, int totalPoints) {
    final sportPoints = records
        .where((r) => r.category == MeritCategory.sports)
        .fold<int>(0, (total, r) => total + r.points);
    final leadershipPoints = records
        .where((r) => r.category == MeritCategory.leadership)
        .fold<int>(0, (total, r) => total + r.points);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green800),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryBox('Sports & Recreation', sportPoints),
          _summaryBox('Leadership & Service', leadershipPoints),
          _summaryBox('TOTAL POINTS', totalPoints, isHighlighted: true),
        ],
      ),
    );
  }

  pw.Widget _summaryBox(String label, int points, {bool isHighlighted = false}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: isHighlighted ? PdfColors.green800 : PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            points.toString(),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: isHighlighted ? PdfColors.white : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildActivityTable(
    List<MeritRecordModel> records,
    DateFormat dateFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green800),
          children: [
            _tableHeader('Date'),
            _tableHeader('Category'),
            _tableHeader('Activity'),
            _tableHeader('Sport'),
            _tableHeader('Points'),
          ],
        ),
        // Data rows
        ...records.map((record) => pw.TableRow(
              children: [
                _tableCell(dateFormat.format(record.activityDate)),
                _tableCell(record.category.displayName),
                _tableCell(record.activityDescription),
                _tableCell(record.sport.displayName),
                _tableCell(record.points.toString(), isCentered: true),
              ],
            )),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text, {bool isCentered = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: isCentered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildVerificationSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VERIFICATION',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This transcript is generated by PutraSportHub and represents activities '
            'recorded in the system. For official merit certification, please submit '
            'this document to the UPM Student Affairs Office for verification.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                    child: pw.SizedBox(height: 30),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Student Signature',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                    child: pw.SizedBox(height: 30),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Verified By (Official Stamp)',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _getCurrentSemester() {
    final now = DateTime.now();
    // UPM Semester 1: Sept-Jan, Semester 2: Feb-June, Special: July-Aug
    if (now.month >= 9 || now.month == 1) {
      return 'Semester 1';
    } else if (now.month >= 2 && now.month <= 6) {
      return 'Semester 2';
    } else {
      return 'Special Semester';
    }
  }

  String _getCurrentAcademicYear() {
    final now = DateTime.now();
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    return '$startYear/${startYear + 1}';
  }
}

/// Merit operation result
class MeritResult {
  final bool success;
  final MeritRecordModel? record;
  final String? errorMessage;

  const MeritResult._({
    required this.success,
    this.record,
    this.errorMessage,
  });

  factory MeritResult.success(MeritRecordModel record) {
    return MeritResult._(success: true, record: record);
  }

  factory MeritResult.failure(String message) {
    return MeritResult._(success: false, errorMessage: message);
  }
}


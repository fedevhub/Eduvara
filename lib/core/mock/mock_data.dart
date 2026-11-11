class MockUser {
  final String name;
  final String username;
  final String info;
  final String role;
  final bool active;
  final String joined;

  const MockUser(
    this.name,
    this.username,
    this.info,
    this.role,
    this.active, [
    this.joined = '24 Juli 2024',
  ]);
}

final List<MockUser> mockSiswa = [
  const MockUser(
    'Fitri Rachmania',
    '0081234567',
    'Kelas 12 RPL',
    'Siswa',
    true,
  ),
  const MockUser(
    'Aprilia Kananti',
    '0082345678',
    'Kelas 11',
    'Siswa',
    true,
  ),
  const MockUser(
    'Josico Devan',
    '0083456789',
    'Kelas 10',
    'Siswa',
    false,
  ),
  const MockUser(
    'Ahmad Bintang',
    '0084567890',
    'Kelas 11',
    'Siswa',
    true,
  ),
  const MockUser(
    'Bunga Lestari',
    '0085678901',
    'Kelas 12',
    'Siswa',
    true,
  ),
];

final List<MockUser> mockGuru = [
  const MockUser(
    'Budi Santoso',
    '198712312010011001',
    'Matematika',
    'Guru',
    true,
  ),
  const MockUser(
    'Dewi Kurniawan',
    '198802012011012002',
    'Bahasa Indonesia',
    'Guru',
    true,
  ),
  const MockUser(
    'Reza Pratama',
    '198903032012011003',
    'KIK',
    'Guru',
    false,
  ),
  const MockUser(
    'Laila Aminah',
    '199004042013012004',
    'Agama',
    'Guru',
    false,
  ),
];

final List<MockUser> mockAdmin = [
  const MockUser('Ahmad Fajar', 'admin-satu', 'Admin', 'Admin', true),
  const MockUser('Fani Pertiwi', 'admin-dua', 'Admin', 'Admin', true),
];

List<MockUser> get allMockUsers => [...mockSiswa, ...mockGuru, ...mockAdmin];

List<MockUser> usersByRole(String role) {
  switch (role) {
    case 'Siswa':
      return mockSiswa;
    case 'Guru':
      return mockGuru;
    default:
      return mockAdmin;
  }
}

void addMockUser(MockUser user) {
  usersByRole(user.role).add(user);
}

void updateMockUser(MockUser oldUser, MockUser newUser) {
  usersByRole(oldUser.role).remove(oldUser);
  usersByRole(newUser.role).add(newUser);
}

void removeMockUser(MockUser user) {
  usersByRole(user.role).remove(user);
}

class MockCourse {
  final String title;
  final String teacher;
  final String subject;
  final int students;
  final int percent;
  final bool active;
  final String description;
  final String level;
  final List<String> studentNames;

  const MockCourse(
    this.title,
    this.teacher,
    this.subject,
    this.students,
    this.percent,
    this.active, {
    this.description = '',
    this.level = '',
    this.studentNames = const [],
  });
}

final List<MockCourse> mockCourses = [
  const MockCourse(
    'Matematika Kelas 10',
    'Budi Santoso',
    'Matematika',
    2,
    72,
    true,
    description: 'Materi dasar matematika.',
    level: 'Kelas 10',
    studentNames: ['Fitri Rachmania', 'Aprilia Kananti'],
  ),
  const MockCourse(
    'Bahasa Indonesia Kelas 11',
    'Dewi Kurniawan',
    'Bahasa Indonesia',
    1,
    45,
    false,
    description: 'Pembelajaran Bahasa Indonesia.',
    level: 'Kelas 11',
    studentNames: ['Ahmad Bintang'],
  ),
];

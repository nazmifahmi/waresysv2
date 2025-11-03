/// Company standards for positions and departments
class CompanyStandards {
  // Standard positions in the company
  static const List<String> positions = [
    'CEO',
    'CTO',
    'CFO',
    'COO',
    'General Manager',
    'Manager',
    'Assistant Manager',
    'Supervisor',
    'Team Leader',
    'Senior Staff',
    'Staff',
    'Junior Staff',
    'Intern',
    'Consultant',
    'Specialist',
    'Analyst',
    'Coordinator',
    'Administrator',
    'Secretary',
    'Driver',
    'Security',
    'Cleaning Service',
  ];

  // Standard departments in the company
  static const List<String> departments = [
    'Executive',
    'Human Resources',
    'Finance & Accounting',
    'Information Technology',
    'Operations',
    'Sales & Marketing',
    'Customer Service',
    'Procurement',
    'Warehouse',
    'Logistics',
    'Quality Control',
    'Research & Development',
    'Legal',
    'Administration',
    'Maintenance',
    'Security',
  ];

  // Get position display name
  static String getPositionDisplayName(String position) {
    return position;
  }

  // Get department display name
  static String getDepartmentDisplayName(String department) {
    return department;
  }

  // Validate if position exists in standards
  static bool isValidPosition(String position) {
    return positions.contains(position);
  }

  // Validate if department exists in standards
  static bool isValidDepartment(String department) {
    return departments.contains(department);
  }
}
class ApiRoutes{
  static const String baseUrl = 'https://mobapis.tvtc.gov.sa';

  static const loginRoute = '$baseUrl/ws/auth';

  static  getExcuseTypesRoute(empNo) => '$baseUrl/GetExecuseType?empno=$empNo';
  static const createExcuseRoute =  '$baseUrl/Execuse/submit';

  static getVacationTypesRoute(empNo) => '$baseUrl/vacationtypes?empno=$empNo';
  static const createVacationRoute =  '$baseUrl/vacation/submit';

  static getDelegatePersonsRoute(empNo, deptId) =>'$baseUrl/GetDelgPersons?empno=$empNo&deptid=$deptId';

  static const String checkEmployeeOtpRoute = '/ws/check_emp_otp/';
  static const String checkEmployeeActivationRoute = '/ws/check_emp_activation/';
  static const String generateEmployeeOtpRoute = '/ws/generate_emp_otp/';
  static const String generateEmployeeActivationRoute = '/ws/emp_activation/';
  static const String verifyEmplyeeServiceRoute = '/ws/verify/';

  static String registerFingerprintRoute = '/ws/register/';

  static String activateDeviceRoute = '/ws/otp/';

  static String doFingerprintRoute = '/ws/fingerprint/';
}
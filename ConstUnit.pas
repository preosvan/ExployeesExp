unit ConstUnit;

interface

uses
  Winapi.Messages;

const
  WM_AFTER_EXPORT = WM_USER + 1;

  SECTION_GENERAL = 'GENERAL';
  KEY_DB_NAME = 'DBName';
  KEY_DB_HOST = 'DBHost';
  KEY_DB_USER_NAME = 'DBUserName';
  KEY_DB_PASS = 'DBPass';

  TN_DEP = 'DEPARTMENTS';
  FN_DEP_ID = 'DEPARTMENT_ID';
  FN_DEP_NAME = 'DEPARTMENT_NAME';
  FN_MANAGER_ID = 'MANAGER_ID';
  FN_LOCATION_ID = 'LOCATION_ID';
  FN_OFFICE_ID = 'OFFICE_ID';

  TN_EMPL = 'EMPLOYEES';
  FN_EMPL_ID = 'EMPLOYEE_ID';
  FN_FIRST_NAME = 'FIRST_NAME';
  FN_LAST_NAME = 'LAST_NAME';
  FN_EMAIL = 'EMAIL';
  FN_PHONE_NUMBER = 'PHONE_NUMBER';
  FN_HIRE_DATE = 'HIRE_DATE';
  FN_JOB_ID = 'JOB_ID';
  FN_SALARY = 'SALARY';
  FN_COMMISSION_PCT = 'COMMISSION_PCT';

  EXP_CSS_FN_TABLE = 'style_table.css';
  EXP_CSS_FN_CAPT_BLUE = 'style_caption_blue.css';
  EXP_CSS_FN_CAPT_BLACK = 'style_caption_black.css';

implementation

end.

BEGIN;

CREATE TABLE Agency (
  agency_code smallint PRIMARY KEY,
  agency_name text,
  agency_abbr text
);

CREATE TABLE LoanType (
  loan_type smallint PRIMARY KEY,
  loan_type_name text
);

CREATE TABLE PropertyType (
  property_type smallint PRIMARY KEY,
  property_type_name text
);

CREATE TABLE LoanPurpose (
  loan_purpose smallint PRIMARY KEY,
  loan_purpose_name text
);

CREATE TABLE OwnerOccupancy (
  owner_occupancy smallint PRIMARY KEY,
  owner_occupancy_name text
);

CREATE TABLE Preapproval (
  preapproval smallint PRIMARY KEY,
  preapproval_name text
);

CREATE TABLE ActionTaken (
  action_taken smallint PRIMARY KEY,
  action_taken_name text
);

CREATE TABLE MSAMD (
  msamd integer PRIMARY KEY,
  msamd_name text
);

CREATE TABLE State (
  state_code smallint PRIMARY KEY,
  state_name text,
  state_abbr text
);

CREATE TABLE County (
  county_code smallint,
  state_code smallint REFERENCES State(state_code),
  county_name text,
  PRIMARY KEY (county_code, state_code)
);

CREATE TABLE EthnicityLookup (
  ethnicity_code smallint PRIMARY KEY,
  ethnicity_name text
);

CREATE TABLE RaceLookup (
  race_code smallint PRIMARY KEY,
  race_name text
);

CREATE TABLE SexLookup (
  sex_code smallint PRIMARY KEY,
  sex_name text
);

CREATE TABLE PurchaserType (
  purchaser_type smallint PRIMARY KEY,
  purchaser_type_name text
);

CREATE TABLE DenialReason (
  denial_reason_code smallint PRIMARY KEY,
  denial_reason_name text
);

CREATE TABLE HOEPAStatus (
  hoepa_status smallint PRIMARY KEY,
  hoepa_status_name text
);

CREATE TABLE LienStatus (
  lien_status smallint PRIMARY KEY,
  lien_status_name text
);

CREATE TABLE EditStatus (
  edit_status text PRIMARY KEY,
  edit_status_name text
);

CREATE TABLE ApplicationDateIndicator (
  application_date_indicator smallint PRIMARY KEY,
  application_date_indicator_name text
);

CREATE TABLE Location (
  location_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  county_code smallint,
  msamd integer,
  state_code smallint,
  census_tract_number numeric,
  population integer,
  minority_population numeric,
  hud_median_family_income integer,
  tract_to_msamd_income numeric,
  number_of_owner_occupied_units integer,
  number_of_1_to_4_family_units integer,
  FOREIGN KEY (state_code) REFERENCES State(state_code),
  FOREIGN KEY (msamd) REFERENCES MSAMD(msamd),
  FOREIGN KEY (county_code, state_code) REFERENCES County(county_code, state_code)
);

CREATE TABLE Application (
  application_id bigint PRIMARY KEY,
  as_of_year smallint,
  respondent_id text,
  agency_code smallint REFERENCES Agency(agency_code),
  loan_type smallint REFERENCES LoanType(loan_type),
  property_type smallint REFERENCES PropertyType(property_type),
  loan_purpose smallint REFERENCES LoanPurpose(loan_purpose),
  owner_occupancy smallint REFERENCES OwnerOccupancy(owner_occupancy),
  loan_amount_000s numeric,
  preapproval smallint REFERENCES Preapproval(preapproval),
  action_taken smallint REFERENCES ActionTaken(action_taken),
  location_id integer REFERENCES Location(location_id),
  applicant_ethnicity smallint REFERENCES EthnicityLookup(ethnicity_code),
  co_applicant_ethnicity smallint REFERENCES EthnicityLookup(ethnicity_code),
  applicant_sex smallint REFERENCES SexLookup(sex_code),
  co_applicant_sex smallint REFERENCES SexLookup(sex_code),
  applicant_income_000s numeric,
  purchaser_type smallint REFERENCES PurchaserType(purchaser_type),
  rate_spread numeric,
  hoepa_status smallint REFERENCES HOEPAStatus(hoepa_status),
  lien_status smallint REFERENCES LienStatus(lien_status),
  edit_status text REFERENCES EditStatus(edit_status),
  sequence_number bigint,
  application_date_indicator smallint REFERENCES ApplicationDateIndicator(application_date_indicator)
);

CREATE TABLE ApplicantRace (
  application_id bigint REFERENCES Application(application_id) ON DELETE CASCADE,
  race_number smallint,
  race_code smallint REFERENCES RaceLookup(race_code),
  PRIMARY KEY (application_id, race_number)
);

CREATE TABLE CoApplicantRace (
  application_id bigint REFERENCES Application(application_id) ON DELETE CASCADE,
  race_number smallint,
  race_code smallint REFERENCES RaceLookup(race_code),
  PRIMARY KEY (application_id, race_number)
);

CREATE TABLE ApplicationDenialReason (
  application_id bigint REFERENCES Application(application_id) ON DELETE CASCADE,
  denial_reason_number smallint,
  denial_reason_code smallint REFERENCES DenialReason(denial_reason_code),
  PRIMARY KEY (application_id, denial_reason_number)
);

INSERT INTO OwnerOccupancy VALUES
  (1, 'Owner-occupied as a principal dwelling'),
  (2, 'Not owner-occupied'),
  (3, 'Not applicable');

INSERT INTO ActionTaken VALUES
  (1, 'Loan originated'),
  (2, 'Application approved but not accepted'),
  (3, 'Application denied by financial institution');

INSERT INTO DenialReason VALUES
  (1, 'Debt-to-income ratio'),
  (2, 'Employment history'),
  (3, 'Credit history');

INSERT INTO Application (
  application_id,
  as_of_year,
  respondent_id,
  owner_occupancy,
  loan_amount_000s,
  action_taken,
  applicant_income_000s
) VALUES
  (1, 2012, 'R000001', 1, 250, 1, 85),
  (2, 2012, 'R000002', 1, 175, 3, 52),
  (3, 2012, 'R000003', 2, 320, 1, 120);

INSERT INTO ApplicationDenialReason VALUES
  (2, 1, 3);

COMMIT;
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
  UNIQUE (
    county_code,
    msamd,
    state_code,
    census_tract_number,
    population,
    minority_population,
    hud_median_family_income,
    tract_to_msamd_income,
    number_of_owner_occupied_units,
    number_of_1_to_4_family_units
  ),
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

INSERT INTO Agency (agency_code, agency_name, agency_abbr)
SELECT DISTINCT
  NULLIF(agency_code, '')::smallint,
  NULLIF(agency_name, ''),
  NULLIF(agency_abbr, '')
FROM Preliminary
WHERE NULLIF(agency_code, '') IS NOT NULL
ORDER BY 1;

INSERT INTO LoanType (loan_type, loan_type_name)
SELECT DISTINCT
  NULLIF(loan_type, '')::smallint,
  NULLIF(loan_type_name, '')
FROM Preliminary
WHERE NULLIF(loan_type, '') IS NOT NULL
ORDER BY 1;

INSERT INTO PropertyType (property_type, property_type_name)
SELECT DISTINCT
  NULLIF(property_type, '')::smallint,
  NULLIF(property_type_name, '')
FROM Preliminary
WHERE NULLIF(property_type, '') IS NOT NULL
ORDER BY 1;

INSERT INTO LoanPurpose (loan_purpose, loan_purpose_name)
SELECT DISTINCT
  NULLIF(loan_purpose, '')::smallint,
  NULLIF(loan_purpose_name, '')
FROM Preliminary
WHERE NULLIF(loan_purpose, '') IS NOT NULL
ORDER BY 1;

INSERT INTO OwnerOccupancy (owner_occupancy, owner_occupancy_name)
SELECT DISTINCT
  NULLIF(owner_occupancy, '')::smallint,
  NULLIF(owner_occupancy_name, '')
FROM Preliminary
WHERE NULLIF(owner_occupancy, '') IS NOT NULL
ORDER BY 1;

INSERT INTO Preapproval (preapproval, preapproval_name)
SELECT DISTINCT
  NULLIF(preapproval, '')::smallint,
  NULLIF(preapproval_name, '')
FROM Preliminary
WHERE NULLIF(preapproval, '') IS NOT NULL
ORDER BY 1;

INSERT INTO ActionTaken (action_taken, action_taken_name)
SELECT DISTINCT
  NULLIF(action_taken, '')::smallint,
  NULLIF(action_taken_name, '')
FROM Preliminary
WHERE NULLIF(action_taken, '') IS NOT NULL
ORDER BY 1;

INSERT INTO MSAMD (msamd, msamd_name)
SELECT DISTINCT
  NULLIF(msamd, '')::integer,
  NULLIF(msamd_name, '')
FROM Preliminary
WHERE NULLIF(msamd, '') IS NOT NULL
ORDER BY 1;

INSERT INTO State (state_code, state_name, state_abbr)
SELECT DISTINCT
  NULLIF(state_code, '')::smallint,
  NULLIF(state_name, ''),
  NULLIF(state_abbr, '')
FROM Preliminary
WHERE NULLIF(state_code, '') IS NOT NULL
ORDER BY 1;

INSERT INTO County (county_code, state_code, county_name)
SELECT DISTINCT
  NULLIF(county_code, '')::smallint,
  NULLIF(state_code, '')::smallint,
  NULLIF(county_name, '')
FROM Preliminary
WHERE NULLIF(county_code, '') IS NOT NULL
  AND NULLIF(state_code, '') IS NOT NULL
ORDER BY 2, 1;

INSERT INTO EthnicityLookup (ethnicity_code, ethnicity_name)
SELECT DISTINCT ethnicity_code, ethnicity_name
FROM (
  SELECT
    NULLIF(applicant_ethnicity, '')::smallint AS ethnicity_code,
    NULLIF(applicant_ethnicity_name, '') AS ethnicity_name
  FROM Preliminary
  WHERE NULLIF(applicant_ethnicity, '') IS NOT NULL

  UNION

  SELECT
    NULLIF(co_applicant_ethnicity, '')::smallint,
    NULLIF(co_applicant_ethnicity_name, '')
  FROM Preliminary
  WHERE NULLIF(co_applicant_ethnicity, '') IS NOT NULL
) x
WHERE ethnicity_code IS NOT NULL
ORDER BY 1;

INSERT INTO RaceLookup (race_code, race_name)
SELECT DISTINCT race_code, race_name
FROM (
  SELECT NULLIF(applicant_race_1, '')::smallint AS race_code, NULLIF(applicant_race_name_1, '') AS race_name FROM Preliminary WHERE NULLIF(applicant_race_1, '') IS NOT NULL
  UNION
  SELECT NULLIF(applicant_race_2, '')::smallint, NULLIF(applicant_race_name_2, '') FROM Preliminary WHERE NULLIF(applicant_race_2, '') IS NOT NULL
  UNION
  SELECT NULLIF(applicant_race_3, '')::smallint, NULLIF(applicant_race_name_3, '') FROM Preliminary WHERE NULLIF(applicant_race_3, '') IS NOT NULL
  UNION
  SELECT NULLIF(applicant_race_4, '')::smallint, NULLIF(applicant_race_name_4, '') FROM Preliminary WHERE NULLIF(applicant_race_4, '') IS NOT NULL
  UNION
  SELECT NULLIF(applicant_race_5, '')::smallint, NULLIF(applicant_race_name_5, '') FROM Preliminary WHERE NULLIF(applicant_race_5, '') IS NOT NULL
  UNION
  SELECT NULLIF(co_applicant_race_1, '')::smallint, NULLIF(co_applicant_race_name_1, '') FROM Preliminary WHERE NULLIF(co_applicant_race_1, '') IS NOT NULL
  UNION
  SELECT NULLIF(co_applicant_race_2, '')::smallint, NULLIF(co_applicant_race_name_2, '') FROM Preliminary WHERE NULLIF(co_applicant_race_2, '') IS NOT NULL
  UNION
  SELECT NULLIF(co_applicant_race_3, '')::smallint, NULLIF(co_applicant_race_name_3, '') FROM Preliminary WHERE NULLIF(co_applicant_race_3, '') IS NOT NULL
  UNION
  SELECT NULLIF(co_applicant_race_4, '')::smallint, NULLIF(co_applicant_race_name_4, '') FROM Preliminary WHERE NULLIF(co_applicant_race_4, '') IS NOT NULL
  UNION
  SELECT NULLIF(co_applicant_race_5, '')::smallint, NULLIF(co_applicant_race_name_5, '') FROM Preliminary WHERE NULLIF(co_applicant_race_5, '') IS NOT NULL
) x
WHERE race_code IS NOT NULL
ORDER BY 1;

INSERT INTO SexLookup (sex_code, sex_name)
SELECT DISTINCT sex_code, sex_name
FROM (
  SELECT
    NULLIF(applicant_sex, '')::smallint AS sex_code,
    NULLIF(applicant_sex_name, '') AS sex_name
  FROM Preliminary
  WHERE NULLIF(applicant_sex, '') IS NOT NULL

  UNION

  SELECT
    NULLIF(co_applicant_sex, '')::smallint,
    NULLIF(co_applicant_sex_name, '')
  FROM Preliminary
  WHERE NULLIF(co_applicant_sex, '') IS NOT NULL
) x
WHERE sex_code IS NOT NULL
ORDER BY 1;

INSERT INTO PurchaserType (purchaser_type, purchaser_type_name)
SELECT DISTINCT
  NULLIF(purchaser_type, '')::smallint,
  NULLIF(purchaser_type_name, '')
FROM Preliminary
WHERE NULLIF(purchaser_type, '') IS NOT NULL
ORDER BY 1;

INSERT INTO DenialReason (denial_reason_code, denial_reason_name)
SELECT DISTINCT denial_reason_code, denial_reason_name
FROM (
  SELECT
    NULLIF(denial_reason_1, '')::smallint AS denial_reason_code,
    NULLIF(denial_reason_name_1, '') AS denial_reason_name
  FROM Preliminary
  WHERE NULLIF(denial_reason_1, '') IS NOT NULL

  UNION

  SELECT
    NULLIF(denial_reason_2, '')::smallint,
    NULLIF(denial_reason_name_2, '')
  FROM Preliminary
  WHERE NULLIF(denial_reason_2, '') IS NOT NULL

  UNION

  SELECT
    NULLIF(denial_reason_3, '')::smallint,
    NULLIF(denial_reason_name_3, '')
  FROM Preliminary
  WHERE NULLIF(denial_reason_3, '') IS NOT NULL
) x
WHERE denial_reason_code IS NOT NULL
ORDER BY 1;

INSERT INTO HOEPAStatus (hoepa_status, hoepa_status_name)
SELECT DISTINCT
  NULLIF(hoepa_status, '')::smallint,
  NULLIF(hoepa_status_name, '')
FROM Preliminary
WHERE NULLIF(hoepa_status, '') IS NOT NULL
ORDER BY 1;

INSERT INTO LienStatus (lien_status, lien_status_name)
SELECT DISTINCT
  NULLIF(lien_status, '')::smallint,
  NULLIF(lien_status_name, '')
FROM Preliminary
WHERE NULLIF(lien_status, '') IS NOT NULL
ORDER BY 1;

INSERT INTO EditStatus (edit_status, edit_status_name)
SELECT DISTINCT
  NULLIF(edit_status, ''),
  NULLIF(edit_status_name, '')
FROM Preliminary
WHERE NULLIF(edit_status, '') IS NOT NULL
ORDER BY 1;

INSERT INTO ApplicationDateIndicator (application_date_indicator, application_date_indicator_name)
SELECT DISTINCT
  NULLIF(application_date_indicator, '')::smallint,
  CASE
    WHEN NULLIF(application_date_indicator, '') = '0' THEN 'Application Date Not Applicable'
    WHEN NULLIF(application_date_indicator, '') = '1' THEN 'Application Date >= 01/01/2004'
    WHEN NULLIF(application_date_indicator, '') = '2' THEN 'Application Date < 01/01/2004'
    ELSE 'Unknown'
  END
FROM Preliminary
WHERE NULLIF(application_date_indicator, '') IS NOT NULL
ORDER BY 1;

INSERT INTO Location (
  county_code,
  msamd,
  state_code,
  census_tract_number,
  population,
  minority_population,
  hud_median_family_income,
  tract_to_msamd_income,
  number_of_owner_occupied_units,
  number_of_1_to_4_family_units
)
SELECT DISTINCT
  NULLIF(county_code, '')::smallint,
  NULLIF(msamd, '')::integer,
  NULLIF(state_code, '')::smallint,
  NULLIF(census_tract_number, '')::numeric,
  NULLIF(population, '')::integer,
  NULLIF(minority_population, '')::numeric,
  NULLIF(hud_median_family_income, '')::integer,
  NULLIF(tract_to_msamd_income, '')::numeric,
  NULLIF(number_of_owner_occupied_units, '')::integer,
  NULLIF(number_of_1_to_4_family_units, '')::integer
FROM Preliminary;

INSERT INTO Application (
  application_id,
  as_of_year,
  respondent_id,
  agency_code,
  loan_type,
  property_type,
  loan_purpose,
  owner_occupancy,
  loan_amount_000s,
  preapproval,
  action_taken,
  location_id,
  applicant_ethnicity,
  co_applicant_ethnicity,
  applicant_sex,
  co_applicant_sex,
  applicant_income_000s,
  purchaser_type,
  rate_spread,
  hoepa_status,
  lien_status,
  edit_status,
  sequence_number,
  application_date_indicator
)
SELECT
  p.id,
  NULLIF(p.as_of_year, '')::smallint,
  NULLIF(p.respondent_id, ''),
  NULLIF(p.agency_code, '')::smallint,
  NULLIF(p.loan_type, '')::smallint,
  NULLIF(p.property_type, '')::smallint,
  NULLIF(p.loan_purpose, '')::smallint,
  NULLIF(p.owner_occupancy, '')::smallint,
  NULLIF(p.loan_amount_000s, '')::numeric,
  NULLIF(p.preapproval, '')::smallint,
  NULLIF(p.action_taken, '')::smallint,
  l.location_id,
  NULLIF(p.applicant_ethnicity, '')::smallint,
  NULLIF(p.co_applicant_ethnicity, '')::smallint,
  NULLIF(p.applicant_sex, '')::smallint,
  NULLIF(p.co_applicant_sex, '')::smallint,
  NULLIF(p.applicant_income_000s, '')::numeric,
  NULLIF(p.purchaser_type, '')::smallint,
  NULLIF(p.rate_spread, '')::numeric,
  NULLIF(p.hoepa_status, '')::smallint,
  NULLIF(p.lien_status, '')::smallint,
  NULLIF(p.edit_status, ''),
  NULLIF(p.sequence_number, '')::bigint,
  NULLIF(p.application_date_indicator, '')::smallint
FROM Preliminary p
JOIN Location l
  ON l.county_code IS NOT DISTINCT FROM NULLIF(p.county_code, '')::smallint
 AND l.msamd IS NOT DISTINCT FROM NULLIF(p.msamd, '')::integer
 AND l.state_code IS NOT DISTINCT FROM NULLIF(p.state_code, '')::smallint
 AND l.census_tract_number IS NOT DISTINCT FROM NULLIF(p.census_tract_number, '')::numeric
 AND l.population IS NOT DISTINCT FROM NULLIF(p.population, '')::integer
 AND l.minority_population IS NOT DISTINCT FROM NULLIF(p.minority_population, '')::numeric
 AND l.hud_median_family_income IS NOT DISTINCT FROM NULLIF(p.hud_median_family_income, '')::integer
 AND l.tract_to_msamd_income IS NOT DISTINCT FROM NULLIF(p.tract_to_msamd_income, '')::numeric
 AND l.number_of_owner_occupied_units IS NOT DISTINCT FROM NULLIF(p.number_of_owner_occupied_units, '')::integer
 AND l.number_of_1_to_4_family_units IS NOT DISTINCT FROM NULLIF(p.number_of_1_to_4_family_units, '')::integer;

INSERT INTO ApplicantRace (application_id, race_number, race_code)
SELECT id, 1, NULLIF(applicant_race_1, '')::smallint
FROM Preliminary
WHERE NULLIF(applicant_race_1, '') IS NOT NULL;

INSERT INTO ApplicantRace (application_id, race_number, race_code)
SELECT id, 2, NULLIF(applicant_race_2, '')::smallint
FROM Preliminary
WHERE NULLIF(applicant_race_2, '') IS NOT NULL;

INSERT INTO ApplicantRace (application_id, race_number, race_code)
SELECT id, 3, NULLIF(applicant_race_3, '')::smallint
FROM Preliminary
WHERE NULLIF(applicant_race_3, '') IS NOT NULL;

INSERT INTO ApplicantRace (application_id, race_number, race_code)
SELECT id, 4, NULLIF(applicant_race_4, '')::smallint
FROM Preliminary
WHERE NULLIF(applicant_race_4, '') IS NOT NULL;

INSERT INTO ApplicantRace (application_id, race_number, race_code)
SELECT id, 5, NULLIF(applicant_race_5, '')::smallint
FROM Preliminary
WHERE NULLIF(applicant_race_5, '') IS NOT NULL;

INSERT INTO CoApplicantRace (application_id, race_number, race_code)
SELECT id, 1, NULLIF(co_applicant_race_1, '')::smallint
FROM Preliminary
WHERE NULLIF(co_applicant_race_1, '') IS NOT NULL;

INSERT INTO CoApplicantRace (application_id, race_number, race_code)
SELECT id, 2, NULLIF(co_applicant_race_2, '')::smallint
FROM Preliminary
WHERE NULLIF(co_applicant_race_2, '') IS NOT NULL;

INSERT INTO CoApplicantRace (application_id, race_number, race_code)
SELECT id, 3, NULLIF(co_applicant_race_3, '')::smallint
FROM Preliminary
WHERE NULLIF(co_applicant_race_3, '') IS NOT NULL;

INSERT INTO CoApplicantRace (application_id, race_number, race_code)
SELECT id, 4, NULLIF(co_applicant_race_4, '')::smallint
FROM Preliminary
WHERE NULLIF(co_applicant_race_4, '') IS NOT NULL;

INSERT INTO CoApplicantRace (application_id, race_number, race_code)
SELECT id, 5, NULLIF(co_applicant_race_5, '')::smallint
FROM Preliminary
WHERE NULLIF(co_applicant_race_5, '') IS NOT NULL;

INSERT INTO ApplicationDenialReason (application_id, denial_reason_number, denial_reason_code)
SELECT id, 1, NULLIF(denial_reason_1, '')::smallint
FROM Preliminary
WHERE NULLIF(denial_reason_1, '') IS NOT NULL;

INSERT INTO ApplicationDenialReason (application_id, denial_reason_number, denial_reason_code)
SELECT id, 2, NULLIF(denial_reason_2, '')::smallint
FROM Preliminary
WHERE NULLIF(denial_reason_2, '') IS NOT NULL;

INSERT INTO ApplicationDenialReason (application_id, denial_reason_number, denial_reason_code)
SELECT id, 3, NULLIF(denial_reason_3, '')::smallint
FROM Preliminary
WHERE NULLIF(denial_reason_3, '') IS NOT NULL;


ALTER TABLE Application
  ALTER COLUMN application_id SET NOT NULL,
  ALTER COLUMN as_of_year SET NOT NULL,
  ALTER COLUMN respondent_id SET NOT NULL,
  ALTER COLUMN agency_code SET NOT NULL,
  ALTER COLUMN loan_type SET NOT NULL,
  ALTER COLUMN property_type SET NOT NULL,
  ALTER COLUMN loan_purpose SET NOT NULL,
  ALTER COLUMN owner_occupancy SET NOT NULL,
  ALTER COLUMN action_taken SET NOT NULL,
  ALTER COLUMN location_id SET NOT NULL;

ALTER TABLE ApplicantRace
  ADD CONSTRAINT chk_applicant_race_number
  CHECK (race_number BETWEEN 1 AND 5);

ALTER TABLE CoApplicantRace
  ADD CONSTRAINT chk_coapplicant_race_number
  CHECK (race_number BETWEEN 1 AND 5);

ALTER TABLE ApplicationDenialReason
  ADD CONSTRAINT chk_denial_reason_number
  CHECK (denial_reason_number BETWEEN 1 AND 3);

ALTER TABLE ApplicantRace
  ALTER COLUMN application_id SET NOT NULL,
  ALTER COLUMN race_number SET NOT NULL,
  ALTER COLUMN race_code SET NOT NULL;

ALTER TABLE CoApplicantRace
  ALTER COLUMN application_id SET NOT NULL,
  ALTER COLUMN race_number SET NOT NULL,
  ALTER COLUMN race_code SET NOT NULL;

ALTER TABLE ApplicationDenialReason
  ALTER COLUMN application_id SET NOT NULL,
  ALTER COLUMN denial_reason_number SET NOT NULL,
  ALTER COLUMN denial_reason_code SET NOT NULL;

COMMIT;
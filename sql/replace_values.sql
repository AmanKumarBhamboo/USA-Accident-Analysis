select * from lapd_crime.crime_data.crime_combined
limit 5;

select distinct lapd_crime.crime_data.crime_combined.victim_sex from lapd_crime.crime_data.crime_combined;

-- Handling the gender in the database
UPDATE lapd_crime.crime_data.crime_combined
SET victim_sex = CASE
    WHEN victim_sex = 'M' THEN 'male'
    WHEN victim_sex = 'F' THEN 'female'
    WHEN victim_sex = '-' or victim_sex is null  THEN 'not_applicable'
    WHEN victim_sex = 'N' THEN 'not_stated'
    WHEN victim_sex = 'H' OR victim_sex = 'X' THEN 'unknown'
    ELSE victim_sex
END
WHERE victim_sex IN ('M', 'F', 'X', 'H', '-', 'N') or victim_sex is null ;

-- Handling the null in premise code
select lapd_crime.crime_data.crime_combined.premise_code from lapd_crime.crime_data.crime_combined
where lapd_crime.crime_data.crime_combined.premise_code = 999;

update lapd_crime.crime_data.crime_combined
set premise_code = 999
where premise_code is null;

-- Handling the premise description

select  distinct lapd_crime.crime_data.crime_combined.premise_description from lapd_crime.crime_data.crime_combined;

update lapd_crime.crime_data.crime_combined
set premise_description = 'unkown'
where premise_description is null;

-- The premise description have * at the end of some entries so I will remove them
update lapd_crime.crime_data.crime_combined
set premise_description = trim(replace(premise_description,'*',''))
where premise_description like '%*%';

-- Handling the null values in weapon code
select distinct lapd_crime.crime_data.crime_combined.weapon_code from lapd_crime.crime_data.crime_combined;

update lapd_crime.crime_data.crime_combined
set weapon_code = 999
where weapon_code is null;

-- Seeing what is the weapon description
select  distinct lapd_crime.crime_data.crime_combined.weapon_description from lapd_crime.crime_data.crime_combined;

update lapd_crime.crime_data.crime_combined
set weapon_description = 'UNKNOWN'
where weapon_description is null;

-- Handling the crime code

ALTER TABLE lapd_crime.crime_data.crime_combined
ADD has_multiple_crime INT;

update lapd_crime.crime_data.crime_combined
set has_multiple_crime = case
    when crime_code_2 is not null or crime_code_3 is not null or crime_code_4 is not null then 1
    else 0 end
where has_multiple_crime is null;

select distinct lapd_crime.crime_data.crime_combined.has_multiple_crime from lapd_crime.crime_data.crime_combined;

--Dropping the crime code 2 ,3 ,4  as they have been calculated in has multiple column
alter table lapd_crime.crime_data.crime_combined
drop column crime_code_2,
drop column crime_code_3,
drop column crime_code_4;

-- combining the lattitude and longitude to get exact location
alter table lapd_crime.crime_data.crime_combined
add column described_location varchar(50);

update lapd_crime.crime_data.crime_combined
set described_location = concat('(',latitude,',',longitude,')')
where described_location is null;

select lapd_crime.crime_data.crime_combined.described_location from lapd_crime.crime_data.crime_combined
where lapd_crime.crime_data.crime_combined.described_location is null;

select lapd_crime.crime_data.crime_combined.described_location from lapd_crime.crime_data.crime_combined
limit 10;

alter table lapd_crime.crime_data.crime_combined
drop column latitude,
drop column longitude;

-- Adjusting time occured
alter table lapd_crime.crime_data.crime_combined
alter column time_occurred type varchar(5);

update lapd_crime.crime_data.crime_combined
set time_occurred = lpad(time_occurred,4,'0')
where length(time_occurred) < 4;

select lapd_crime.crime_data.crime_combined.time_occurred from lapd_crime.crime_data.crime_combined
where lapd_crime.crime_data.crime_combined.time_occurred is not null;

update lapd_crime.crime_data.crime_combined
set time_occurred = concat(left(time_occurred,2),':',right(time_occurred,2))
where time_occurred is not null;

ALTER TABLE lapd_crime.crime_data.crime_combined
ALTER COLUMN time_occurred TYPE TIME using time_occurred::time;

-- Adding a new column named which part of the day
alter table lapd_crime.crime_data.crime_combined
add column part_of_day varchar(15);

UPDATE lapd_crime.crime_data.crime_combined
SET part_of_day = CASE
    WHEN EXTRACT(HOUR FROM time_occurred) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM time_occurred) BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM time_occurred) BETWEEN 17 AND 23 THEN 'Evening'
    ELSE 'Night'
END
where time_occurred is not null;


--Seeing the final table

select * from lapd_crime.crime_data.crime_combined
limit 10;

-- Updating the cross street
update lapd_crime.crime_data.crime_combined
set cross_street = 'none'
where cross_street is null;

UPDATE lapd_crime.crime_data.crime_combined
SET cross_street = TRIM(REGEXP_REPLACE(cross_street, '\s+', ' ', 'g'))
WHERE cross_street IS NOT NULL;

-- Treating the victim descent
select distinct lapd_crime.crime_data.crime_combined.victim_descent from lapd_crime.crime_data.crime_combined;

UPDATE lapd_crime.crime_data.crime_combined
SET victim_descent = CASE
    WHEN victim_descent IN ('H') THEN 'Hispanic'
    WHEN victim_descent IN ('W') THEN 'White'
    WHEN victim_descent IN ('B') THEN 'Black'
    WHEN victim_descent IN ('A', 'C', 'D', 'F', 'G', 'J', 'K', 'L', 'P', 'S', 'U', 'V', 'Z') THEN 'Asian / Pacific Islander'
    ELSE 'Other / Unknown'
END
WHERE victim_descent IN ('H', 'W', 'B', 'A', 'C', 'D', 'F', 'G', 'J', 'K', 'L', 'P', 'S', 'U', 'V', 'Z','-','I','O','X') or victim_descent is null;

-- Seeing the table
select  * from lapd_crime.crime_data.crime_combined
limit 10 ;

select lapd_crime.crime_data.crime_combined.modus_operandi_codes from lapd_crime.crime_data.crime_combined
where modus_operandi_codes is null;

UPDATE lapd_crime.crime_data.crime_combined
SET modus_operandi_codes = 'NONE'
WHERE modus_operandi_codes IS NULL OR TRIM(modus_operandi_codes) = '';

-- Clearing the city names

UPDATE lapd_crime.crime_data.crime_combined
SET street_address = TRIM(REGEXP_REPLACE(street_address, '\s+', ' ', 'g'))
WHERE street_address IS NOT NULL;

-- Treating status code
select distinct lapd_crime.crime_data.crime_combined.status_code from lapd_crime.crime_data.crime_combined;

UPDATE lapd_crime.crime_data.crime_combined
SET status_code = CASE
    WHEN TRIM(status_code) = '13' THEN 'AO'
    WHEN TRIM(status_code) = '19' THEN 'AA'
    WHEN status_code IS NULL THEN 'Unknown'
    ELSE status_code
END
where status_code in ('13','19',null);

-- Treating the crime description
UPDATE lapd_crime.crime_data.crime_combined
SET crime_description = TRIM(REGEXP_REPLACE(crime_description, '\s+', ' ', 'g'))
WHERE crime_description IS NOT NULL;

-- Changing the data type of the date columns
ALTER TABLE lapd_crime.crime_data.crime_combined
ALTER COLUMN date_reported TYPE DATE
USING TO_DATE(date_reported, 'MM/DD/YYYY HH:MI:SS AM');

ALTER TABLE lapd_crime.crime_data.crime_combined
ALTER COLUMN date_occurred TYPE DATE
USING TO_DATE(date_occurred, 'MM/DD/YYYY HH:MI:SS AM');
--Seeing the final table and no further changes
select * from lapd_crime.crime_data.crime_combined
limit 10 ;

-- Saving the data
COPY lapd_crime.crime_data.crime_combined
TO '/Users/apple/Downloads/crime_combined.csv'
WITH (FORMAT CSV, HEADER TRUE, FORCE_QUOTE *);
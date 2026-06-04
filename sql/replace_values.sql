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


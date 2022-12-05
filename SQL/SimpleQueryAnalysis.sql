-- Checking to see if all the table loaded properly

SELECT TOP (1000) *
FROM Student_demographic.dbo.Student_data_17_18_V2

SELECT TOP (1000) *
FROM Student_demographic.dbo.Student_data_18_19_V2

SELECT TOP (1000) *
FROM Student_demographic.dbo.Student_data_19_20_V2


-- Did BoardType and SchoolType remain unchanged over the 3 year period?

SELECT	C.[Board Type],C.[School Type],C.Total_2018,C.Total_2019,D.Total_2020, (C.Total_2019-C.Total_2018) AS Change_18_to_19,
		(D.Total_2020-C.Total_2019) AS Change_19_to_20
FROM (SELECT A.[Board Type],A.[School Type],A.Total_2018,B.Total_2019
	  FROM	(SELECT DISTINCT [Board Type], [School Type], COUNT([School Type]) AS Total_2018
			FROM Student_demographic.dbo.Student_data_17_18_V2
			GROUP BY [Board Type], [School Type]
			HAVING [School Type] IS NOT NULL) AS A
	  JOIN (SELECT DISTINCT [Board Type], [School Type], COUNT([School Type]) AS Total_2019
			FROM Student_demographic.dbo.Student_data_18_19_V2
			GROUP BY [Board Type], [School Type]
			HAVING [School Type] IS NOT NULL) AS B 
	  ON	A.[Board Type] = B.[Board Type] AND A.[School Type] = B.[School Type]) AS C
JOIN	(SELECT [Board Type], [School Type], COUNT([School Type]) AS Total_2020
		FROM Student_demographic.dbo.Student_data_19_20_V2
		GROUP BY [Board Type], [School Type]
		HAVING [School Type] IS NOT NULL) AS D
ON		C.[Board Type] = D.[Board Type] AND C.[School Type] = D.[School Type]
ORDER BY C.Total_2018 DESC 

-- There seems to be a small variation indicating that some of the entries either got removed or added over these 3 years.
-- However the change is insignificant. 

-- Since Public and Catholic school types make up majority of our data, from this onwards our focus will be on these two scool types only.


-- Different Grade Range over these 3 year period for public and catholic schools and will limit the grade range to top 6

SELECT D.[Grade Range], D.Total_2018, D.Total_2019, C.Total_2020 
FROM (SELECT DISTINCT	[Grade Range], COUNT([Grade Range]) AS Total_2020
	  FROM Student_demographic.dbo.Student_data_19_20_V2
	  WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
	  GROUP BY [Grade Range]
	  HAVING [Grade Range] IS NOT NULL) AS C
JOIN (SELECT B.[Grade Range], B.Total_2018, A.Total_2019 
	  FROM	(SELECT DISTINCT	[Grade Range], COUNT([Grade Range]) AS Total_2019
			FROM Student_demographic.dbo.Student_data_18_19_V2
			WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
			GROUP BY [Grade Range]
			HAVING [Grade Range] IS NOT NULL) AS A
	  JOIN (SELECT DISTINCT	[Grade Range], COUNT([Grade Range]) AS Total_2018
			FROM Student_demographic.dbo.Student_data_17_18_V2
			WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
			GROUP BY [Grade Range]
			HAVING [Grade Range] IS NOT NULL) AS B
	  ON   A.[Grade Range] = B.[Grade Range]) AS D
ON   C.[Grade Range] = D.[Grade Range]
WHERE D.Total_2018 > 80
ORDER BY  D.Total_2018 DESC

-- Are there schools with same name in the same city?

SELECT DISTINCT City, [School Name], COUNT([School Name]) AS Total_Schools
FROM		Student_demographic.dbo.Student_data_18_19_V2
WHERE		[School Name] IS NOT NULL
GROUP BY	City, [School Name]
HAVING		City IS NOT NULL
ORDER BY	2 DESC

SELECT DISTINCT City, [School Name], COUNT([School Name]) AS Total_Schools
FROM		Student_demographic.dbo.Student_data_17_18_V2
WHERE		[School Name] IS NOT NULL
GROUP BY	City, [School Name]
HAVING		City IS NOT NULL
ORDER BY	2 DESC

SELECT DISTINCT City, [School Name], COUNT([School Name]) AS Total_Schools
FROM		Student_demographic.dbo.Student_data_19_20_V2
WHERE		[School Name] IS NOT NULL
GROUP BY	City, [School Name]
HAVING		City IS NOT NULL
ORDER BY	2 DESC

-- No (for all three years)


-- Breakdown by City (for Public and Catholic Schools and for Grade Ranges:
-- JK-8, 9-12, JK-6, 7-8, JK-5 and 6-8)

-- Saving this query for Tableau visualization

CREATE OR ALTER VIEW SchoolsByCity_2019 AS
SELECT DISTINCT City, AVG(CAST(Enrolment AS INT)) AS Average_Enrollment,
				MIN(CAST(Enrolment AS INT)) as Min_Enrolment , MAX(CAST(Enrolment AS INT)) as Max_Enrolment,
				COUNT([School Name]) AS Total_Schools,
				COUNT(CASE WHEN [School Level] = 'Elementary' THEN 1 END) AS Total_Elementary,
				COUNT(CASE WHEN [School Level] = 'Secondary' THEN 1 END) AS Total_Secondary, 
				AVG(CAST([first_not _eng_percent] AS INT)) AS Avg_percent_Students_Lang_Not_Eng,
				AVG(CAST([first_not_french_percent] AS INT)) AS Avg_percent_Students_Lang_Not_French,
				AVG(CAST([special_ed_percent] AS INT)) AS Avg_percent_providing_special_ed,
				AVG(CAST([gifted_percent] AS INT)) AS Avg_percent_gifted
FROM		Student_demographic.dbo.Student_data_18_19_V2 
WHERE		Enrolment != 'SP' AND 
			([School Type] = 'Public' OR [School Type] = 'Catholic' ) AND
			[first_not _eng_percent] IS NOT NULL AND
			[first_not_french_percent] IS NOT NULL AND
			Enrolment IS NOT NULL AND
			[School Level] IS NOT NULL AND
			[Grade Range] IN (SELECT A.[Grade Range]
					   FROM	(SELECT DISTINCT  [Grade Range], COUNT([Grade Range]) AS Total_2019
						 FROM Student_demographic.dbo.Student_data_18_19_V2
						 WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
						 GROUP BY [Grade Range]
						 HAVING [Grade Range] IS NOT NULL) AS A
					   WHERE A.Total_2019 > 80) AND
			[special_ed_percent] IS NOT NULL AND
			[gifted_percent] IS NOT NULL
GROUP BY	City
HAVING		City IS NOT NULL

-- Percentage of students who are new to Canada from a Non-English speaking country and 
-- percentage of students who are new to Canada from a Non-French speaking country are not mutually exclusive so can be misleading so for example
-- if 10% of students who are new to Canada from a Non-English speaking country may also be the case that the country is not french-speaking.

CREATE OR ALTER VIEW SchoolsByCity_2018 AS
SELECT DISTINCT City, AVG(CAST(Enrolment AS INT)) AS Average_Enrollment,
				MIN(CAST(Enrolment AS INT)) as Min_Enrolment , MAX(CAST(Enrolment AS INT)) as Max_Enrolment,
				COUNT([School Name]) AS Total_Schools,
				COUNT(CASE WHEN [School Level] = 'Elementary' THEN 1 END) AS Total_Elementary,
				COUNT(CASE WHEN [School Level] = 'Secondary' THEN 1 END) AS Total_Secondary, 
				AVG(CAST([first_not _eng_percent] AS INT)) AS Avg_percent_Students_Lang_Not_Eng,
				AVG(CAST([first_not_french_percent] AS INT)) AS Avg_percent_Students_Lang_Not_French,
				AVG(CAST([special_ed_percent] AS INT)) AS Avg_percent_providing_special_ed,
				AVG(CAST([gifted_percent] AS INT)) AS Avg_percent_gifted
FROM		Student_demographic.dbo.Student_data_17_18_V2 
WHERE		([School Type] = 'Public' OR [School Type] = 'Catholic' ) AND
		[first_not _eng_percent] IS NOT NULL AND
		[first_not_french_percent] IS NOT NULL AND
		Enrolment IS NOT NULL AND
		[School Level] IS NOT NULL AND
		[Grade Range] IN (SELECT A.[Grade Range]
				  FROM	(SELECT DISTINCT [Grade Range], COUNT([Grade Range]) AS Total_2018
					  FROM Student_demographic.dbo.Student_data_17_18_V2
					  WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
					  GROUP BY [Grade Range]
				          HAVING [Grade Range] IS NOT NULL) AS A
				   WHERE A.Total_2018 > 80) AND
		[special_ed_percent] IS NOT NULL AND
		[gifted_percent] IS NOT NULL
GROUP BY	City
HAVING		City IS NOT NULL

CREATE OR ALTER VIEW SchoolsByCity_2020 AS
SELECT DISTINCT City, AVG(CAST(Enrolment AS INT)) AS Average_Enrollment,
				MIN(CAST(Enrolment AS INT)) as Min_Enrolment , MAX(CAST(Enrolment AS INT)) as Max_Enrolment,
				COUNT([School Name]) AS Total_Schools,
				COUNT(CASE WHEN [School Level] = 'Elementary' THEN 1 END) AS Total_Elementary,
				COUNT(CASE WHEN [School Level] = 'Secondary' THEN 1 END) AS Total_Secondary, 
				AVG(CAST([first_not _eng_percent] AS INT)) AS Avg_percent_Students_Lang_Not_Eng,
				AVG(CAST([first_not_french_percent] AS INT)) AS Avg_percent_Students_Lang_Not_French,
				AVG(CAST([special_ed_percent] AS INT)) AS Avg_percent_providing_special_ed,
				AVG(CAST([gifted_percent] AS INT)) AS Avg_percent_gifted
FROM		Student_demographic.dbo.Student_data_19_20_V2 
WHERE		([School Type] = 'Public' OR [School Type] = 'Catholic' ) AND
		[first_not _eng_percent] IS NOT NULL AND
		[first_not_french_percent] IS NOT NULL AND
		Enrolment IS NOT NULL AND
		[School Level] IS NOT NULL AND
		[Grade Range] IN (SELECT A.[Grade Range]
				  FROM	(SELECT DISTINCT [Grade Range], COUNT([Grade Range]) AS Total_2020
					 FROM Student_demographic.dbo.Student_data_19_20_V2
					 WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
					 GROUP BY [Grade Range]
					 HAVING [Grade Range] IS NOT NULL) AS A
					 WHERE A.Total_2020 > 80) AND
		[special_ed_percent] IS NOT NULL AND
		[gifted_percent] IS NOT NULL
GROUP BY	City
HAVING		City IS NOT NULL


-- Grade breakdown by City (for Public and Catholic Schools and for Grade Ranges:
-- JK-8, 9-12, JK-6, 7-8, JK-5 and 6-8)

SELECT DISTINCT City, AVG(TRY_CONVERT(float,grade_3_reading_prop)) *100 AS Avg_Grade_3_Reading_percent,
				AVG(TRY_CONVERT(float,grade_3_math_prop)) *100 AS Avg_Grade_3_Math_percent,
				AVG(TRY_CONVERT(float,grade_3_writing_prop)) *100 AS Avg_Grade_3_Writing_percent,
				AVG(TRY_CONVERT(float,grade_6_reading_prop)) *100 AS Avg_Grade_6_Reading_percent,
				AVG(TRY_CONVERT(float,grade_6_math_prop)) *100 AS Avg_Grade_6_Math_percent,
				AVG(TRY_CONVERT(float,grade_6_writing_prop)) *100 AS Avg_Grade_6_Writing_percent
				--AVG(TRY_CONVERT(float,grade_9_acc_math_prop)) *100 AS Avg_Grade_9_ACC_Math_percent,
				--AVG(TRY_CONVERT(float,grade_9_ap_math_prop)) *100 AS Avg_Grade_9_AP_Math_percent,
				--AVG(TRY_CONVERT(float,grade_10_osslt_pass_prop)) *100 AS Avg_Grade_10_OSSLT_pass_percent
FROM		Student_demographic.dbo.Student_data_19_20_V2 
WHERE		grade_3_reading_prop != 'SP' AND 
			grade_3_reading_prop != 'NA' AND 
			grade_3_reading_prop IS NOT NULL AND
			grade_3_math_prop != 'SP' AND 
			grade_3_math_prop != 'NA' AND 
			grade_3_math_prop IS NOT NULL AND
			grade_3_writing_prop != 'SP' AND 
			grade_3_writing_prop != 'NA' AND 
			grade_3_writing_prop IS NOT NULL AND
			grade_6_reading_prop != 'SP' AND 
			grade_6_reading_prop != 'NA' AND 
			grade_6_reading_prop IS NOT NULL AND
			grade_6_math_prop != 'SP' AND 
			grade_6_math_prop != 'NA' AND 
			grade_6_math_prop IS NOT NULL AND
			grade_6_writing_prop != 'SP' AND 
			grade_6_writing_prop != 'NA' AND 
			grade_6_writing_prop IS NOT NULL AND
			--grade_9_acc_math_prop != 'SP' AND 
			--grade_9_acc_math_prop != 'NA' AND 
			--grade_9_acc_math_prop IS NOT NULL AND
			--grade_9_ap_math_prop != 'SP' AND 
			--grade_9_ap_math_prop != 'NA' AND 
			--grade_9_ap_math_prop IS NOT NULL AND
			--grade_10_osslt_pass_prop != 'SP' AND 
			--grade_10_osslt_pass_prop != 'NA' AND 
			--grade_10_osslt_pass_prop IS NOT NULL AND
			([School Type] = 'Public' OR [School Type] = 'Catholic' ) AND
			grade_3_reading_prop IS NOT NULL AND
			[Grade Range] IN (SELECT A.[Grade Range]
							  FROM	(SELECT DISTINCT	[Grade Range], COUNT([Grade Range]) AS Total_2020
									FROM Student_demographic.dbo.Student_data_19_20_V2
									WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
									GROUP BY [Grade Range]
									HAVING [Grade Range] IS NOT NULL) AS A
							  WHERE A.Total_2020 > 80)
GROUP BY	City
HAVING		City IS NOT NULL
ORDER BY 2 DESC

-- Grade 9 and 10 have too many Null

-- Temp Table (Grade,household income and parent info By City)

DROP TABLE IF EXISTS GradeByCity_19_20
CREATE TABLE GradeByCity_19_20
(
City nvarchar(255),
Avg_Grade_3_Reading_percent float,
Avg_Grade_3_Math_percent float,
Avg_Grade_3_Writing_percent float,
Avg_Grade_6_Reading_percent float,
Avg_Grade_6_Math_percent float,
Avg_Grade_6_Writing_percent float,
Avg_Low_Income_percent int,
Avg_parent_no_ed_percent int
)

INSERT INTO GradeByCity_19_20
SELECT DISTINCT City, AVG(TRY_CONVERT(float,grade_3_reading_prop)) *100 AS Avg_Grade_3_Reading_percent,
				AVG(TRY_CONVERT(float,grade_3_math_prop)) *100 AS Avg_Grade_3_Math_percent,
				AVG(TRY_CONVERT(float,grade_3_writing_prop)) *100 AS Avg_Grade_3_Writing_percent,
				AVG(TRY_CONVERT(float,grade_6_reading_prop)) *100 AS Avg_Grade_6_Reading_percent,
				AVG(TRY_CONVERT(float,grade_6_math_prop)) *100 AS Avg_Grade_6_Math_percent,
				AVG(TRY_CONVERT(float,grade_6_writing_prop)) *100 AS Avg_Grade_6_Writing_percent,
				--AVG(TRY_CONVERT(float,grade_9_acc_math_prop)) *100 AS Avg_Grade_9_ACC_Math_percent,
				--AVG(TRY_CONVERT(float,grade_9_ap_math_prop)) *100 AS Avg_Grade_9_AP_Math_percent,
				--AVG(TRY_CONVERT(float,grade_10_osslt_pass_prop)) *100 AS Avg_Grade_10_OSSLT_pass_percent
				AVG(CAST(low_income_house_percent AS INT)) AS Avg_Low_Income_percent,
				AVG(CAST(parent_no_ed_percent AS INT)) AS Avg_parent_no_ed_percent
FROM		Student_demographic.dbo.Student_data_19_20_V2 
WHERE		grade_3_reading_prop != 'SP' AND 
			grade_3_reading_prop != 'NA' AND 
			grade_3_reading_prop IS NOT NULL AND
			grade_3_math_prop != 'SP' AND 
			grade_3_math_prop != 'NA' AND 
			grade_3_math_prop IS NOT NULL AND
			grade_3_writing_prop != 'SP' AND 
			grade_3_writing_prop != 'NA' AND 
			grade_3_writing_prop IS NOT NULL AND
			grade_6_reading_prop != 'SP' AND 
			grade_6_reading_prop != 'NA' AND 
			grade_6_reading_prop IS NOT NULL AND
			grade_6_math_prop != 'SP' AND 
			grade_6_math_prop != 'NA' AND 
			grade_6_math_prop IS NOT NULL AND
			grade_6_writing_prop != 'SP' AND 
			grade_6_writing_prop != 'NA' AND 
			grade_6_writing_prop IS NOT NULL AND
			--grade_9_acc_math_prop != 'SP' AND 
			--grade_9_acc_math_prop != 'NA' AND 
			--grade_9_acc_math_prop IS NOT NULL AND
			--grade_9_ap_math_prop != 'SP' AND 
			--grade_9_ap_math_prop != 'NA' AND 
			--grade_9_ap_math_prop IS NOT NULL AND
			--grade_10_osslt_pass_prop != 'SP' AND 
			--grade_10_osslt_pass_prop != 'NA' AND 
			--grade_10_osslt_pass_prop IS NOT NULL AND
			low_income_house_percent IS NOT NULL AND
			parent_no_ed_percent IS NOT NULL AND
			parent_no_ed_percent != 'SP' AND
			([School Type] = 'Public' OR [School Type] = 'Catholic' ) AND
			grade_3_reading_prop IS NOT NULL AND
			[Grade Range] IN (SELECT A.[Grade Range]
					  FROM	(SELECT DISTINCT  [Grade Range], COUNT([Grade Range]) AS Total_2020
						 FROM Student_demographic.dbo.Student_data_19_20_V2
						  WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
						  GROUP BY [Grade Range]
						   HAVING [Grade Range] IS NOT NULL) AS A
					   WHERE A.Total_2020 > 80)
GROUP BY	City
HAVING		City IS NOT NULL

SELECT *
FROM GradeByCity_19_20
ORDER BY 1 

-- Temp table for 2018-2019

DROP TABLE IF EXISTS GradeByCity_18_19
CREATE TABLE GradeByCity_18_19
(
City nvarchar(255),
Avg_Grade_3_Reading_percent float,
Avg_Grade_3_Math_percent float,
Avg_Grade_3_Writing_percent float,
Avg_Grade_6_Reading_percent float,
Avg_Grade_6_Math_percent float,
Avg_Grade_6_Writing_percent float,
Avg_Low_Income_percent int,
Avg_parent_no_ed_percent int
)

INSERT INTO GradeByCity_18_19
SELECT DISTINCT City, AVG(TRY_CONVERT(float,grade_3_reading_prop)) *100 AS Avg_Grade_3_Reading_percent,
				AVG(TRY_CONVERT(float,grade_3_math_prop)) *100 AS Avg_Grade_3_Math_percent,
				AVG(TRY_CONVERT(float,grade_3_writing_prop)) *100 AS Avg_Grade_3_Writing_percent,
				AVG(TRY_CONVERT(float,grade_6_reading_prop)) *100 AS Avg_Grade_6_Reading_percent,
				AVG(TRY_CONVERT(float,grade_6_math_prop)) *100 AS Avg_Grade_6_Math_percent,
				AVG(TRY_CONVERT(float,grade_6_writing_prop)) *100 AS Avg_Grade_6_Writing_percent,
				--AVG(TRY_CONVERT(float,grade_9_acc_math_prop)) *100 AS Avg_Grade_9_ACC_Math_percent,
				--AVG(TRY_CONVERT(float,grade_9_ap_math_prop)) *100 AS Avg_Grade_9_AP_Math_percent,
				--AVG(TRY_CONVERT(float,grade_10_osslt_pass_prop)) *100 AS Avg_Grade_10_OSSLT_pass_percent
				AVG(CAST(low_income_house_percent AS INT)) AS Avg_Low_Income_percent,
				AVG(CAST(parent_no_ed_percent AS INT)) AS Avg_parent_no_ed_percent
FROM		Student_demographic.dbo.Student_data_18_19_V2 
WHERE		grade_3_reading_prop != 'SP' AND 
			grade_3_reading_prop != 'NA' AND 
			grade_3_reading_prop IS NOT NULL AND
			grade_3_math_prop != 'SP' AND 
			grade_3_math_prop != 'NA' AND 
			grade_3_math_prop IS NOT NULL AND
			grade_3_writing_prop != 'SP' AND 
			grade_3_writing_prop != 'NA' AND 
			grade_3_writing_prop IS NOT NULL AND
			grade_6_reading_prop != 'SP' AND 
			grade_6_reading_prop != 'NA' AND 
			grade_6_reading_prop IS NOT NULL AND
			grade_6_math_prop != 'SP' AND 
			grade_6_math_prop != 'NA' AND 
			grade_6_math_prop IS NOT NULL AND
			grade_6_writing_prop != 'SP' AND 
			grade_6_writing_prop != 'NA' AND 
			grade_6_writing_prop IS NOT NULL AND
			--grade_9_acc_math_prop != 'SP' AND 
			--grade_9_acc_math_prop != 'NA' AND 
			--grade_9_acc_math_prop IS NOT NULL AND
			--grade_9_ap_math_prop != 'SP' AND 
			--grade_9_ap_math_prop != 'NA' AND 
			--grade_9_ap_math_prop IS NOT NULL AND
			--grade_10_osslt_pass_prop != 'SP' AND 
			--grade_10_osslt_pass_prop != 'NA' AND 
			--grade_10_osslt_pass_prop IS NOT NULL AND
			low_income_house_percent IS NOT NULL AND
			parent_no_ed_percent IS NOT NULL AND
			parent_no_ed_percent != 'SP' AND
			([School Type] = 'Public' OR [School Type] = 'Catholic' ) AND
			grade_3_reading_prop IS NOT NULL AND
			[Grade Range] IN (SELECT A.[Grade Range]
					  FROM	(SELECT DISTINCT  [Grade Range], COUNT([Grade Range]) AS Total_2019
						 FROM Student_demographic.dbo.Student_data_18_19_V2
						 WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
						 GROUP BY [Grade Range]
						 HAVING [Grade Range] IS NOT NULL) AS A
						 WHERE A.Total_2019 > 80)
GROUP BY	City
HAVING		City IS NOT NULL

-- Temp table for 2017-2018

DROP TABLE IF EXISTS GradeByCity_17_18
CREATE TABLE GradeByCity_17_18
(
City nvarchar(255),
Avg_Grade_3_Reading_percent float,
Avg_Grade_3_Math_percent float,
Avg_Grade_3_Writing_percent float,
Avg_Grade_6_Reading_percent float,
Avg_Grade_6_Math_percent float,
Avg_Grade_6_Writing_percent float,
Avg_Low_Income_percent int,
Avg_parent_no_ed_percent int
)

INSERT INTO GradeByCity_17_18
SELECT DISTINCT City, AVG(TRY_CONVERT(float,grade_3_reading_prop)) *100 AS Avg_Grade_3_Reading_percent,
				AVG(TRY_CONVERT(float,grade_3_math_prop)) *100 AS Avg_Grade_3_Math_percent,
				AVG(TRY_CONVERT(float,grade_3_writing_prop)) *100 AS Avg_Grade_3_Writing_percent,
				AVG(TRY_CONVERT(float,grade_6_reading_prop)) *100 AS Avg_Grade_6_Reading_percent,
				AVG(TRY_CONVERT(float,grade_6_math_prop)) *100 AS Avg_Grade_6_Math_percent,
				AVG(TRY_CONVERT(float,grade_6_writing_prop)) *100 AS Avg_Grade_6_Writing_percent,
				--AVG(TRY_CONVERT(float,grade_9_acc_math_prop)) *100 AS Avg_Grade_9_ACC_Math_percent,
				--AVG(TRY_CONVERT(float,grade_9_ap_math_prop)) *100 AS Avg_Grade_9_AP_Math_percent,
				--AVG(TRY_CONVERT(float,grade_10_osslt_pass_prop)) *100 AS Avg_Grade_10_OSSLT_pass_percent
				AVG(CAST(low_income_house_percent AS INT)) AS Avg_Low_Income_percent,
				AVG(CAST(parent_no_ed_percent AS INT)) AS Avg_parent_no_ed_percent
FROM		Student_demographic.dbo.Student_data_17_18_V2 
WHERE		grade_3_reading_prop != 'SP' AND 
			grade_3_reading_prop != 'NA' AND 
			grade_3_reading_prop IS NOT NULL AND
			grade_3_math_prop != 'SP' AND 
			grade_3_math_prop != 'NA' AND 
			grade_3_math_prop IS NOT NULL AND
			grade_3_writing_prop != 'SP' AND 
			grade_3_writing_prop != 'NA' AND 
			grade_3_writing_prop IS NOT NULL AND
			grade_6_reading_prop != 'SP' AND 
			grade_6_reading_prop != 'NA' AND 
			grade_6_reading_prop IS NOT NULL AND
			grade_6_math_prop != 'SP' AND 
			grade_6_math_prop != 'NA' AND 
			grade_6_math_prop IS NOT NULL AND
			grade_6_writing_prop != 'SP' AND 
			grade_6_writing_prop != 'NA' AND 
			grade_6_writing_prop IS NOT NULL AND
			--grade_9_acc_math_prop != 'SP' AND 
			--grade_9_acc_math_prop != 'NA' AND 
			--grade_9_acc_math_prop IS NOT NULL AND
			--grade_9_ap_math_prop != 'SP' AND 
			--grade_9_ap_math_prop != 'NA' AND 
			--grade_9_ap_math_prop IS NOT NULL AND
			--grade_10_osslt_pass_prop != 'SP' AND 
			--grade_10_osslt_pass_prop != 'NA' AND 
			--grade_10_osslt_pass_prop IS NOT NULL AND
			low_income_house_percent IS NOT NULL AND
			parent_no_ed_percent IS NOT NULL AND
			parent_no_ed_percent != 'SP' AND
			([School Type] = 'Public' OR [School Type] = 'Catholic' ) AND
			grade_3_reading_prop IS NOT NULL AND
			[Grade Range] IN (SELECT A.[Grade Range]
					  FROM	(SELECT DISTINCT [Grade Range], COUNT([Grade Range]) AS Total_2018
						 FROM Student_demographic.dbo.Student_data_17_18_V2
						 WHERE	[School Type] = 'Public' or [School Type] = 'Catholic'
						 GROUP BY [Grade Range]
						 HAVING [Grade Range] IS NOT NULL) AS A
						 WHERE A.Total_2018 > 80)
GROUP BY	City
HAVING		City IS NOT NULL


SELECT *
FROM GradeByCity_17_18 

SELECT *
FROM GradeByCity_18_19

SELECT *
FROM GradeByCity_19_20 




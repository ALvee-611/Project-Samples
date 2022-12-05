-- Checking out the first 100 rows of the Marvel table
SELECT TOP 100 *
FROM Twitter.dbo.Marvel

-- Checking out the first 100 rows of the DC table
SELECT TOP 100  *
FROM Twitter.dbo.DC

-- Data Cleaning + Exploring The DC table

-- Separate date and time into two separate columns
SELECT created_at, CONVERT(DATE,created_at), CONVERT(varchar,created_at,24)
FROM Twitter.dbo.DC

-- ADD them to the table
ALTER TABLE Twitter.dbo.DC 
ADD time_of_tweet varchar(50),
	date_of_tweet Date;

-- FOR DC
UPDATE Twitter.dbo.DC
SET date_of_tweet = CONVERT(DATE,created_at),
	time_of_tweet = CONVERT(varchar,created_at,24)

-- FOR Marvel
ALTER TABLE Twitter.dbo.Marvel 
ADD time_of_tweet varchar(50),
	date_of_tweet Date;

UPDATE Twitter.dbo.Marvel
SET date_of_tweet = CONVERT(DATE,created_at),
	time_of_tweet = CONVERT(varchar,created_at,24)

-- Check location of tweet if available

SELECT place_name, place_full_name, place_type,country, location
FROM Twitter.dbo.DC
WHERE place_name IS NOT NULL OR
	  place_full_name IS NOT NULL OR
	  place_type IS NOT NULL OR
	  country IS NOT NULL OR
	  location IS NOT NULL;

-- Since all the values appear to be NULL, I will drop these columns to make it easier to work with the data

ALTER TABLE Twitter.dbo.DC
DROP COLUMN place_name, place_full_name, place_type,
	 country, location;

SELECT place_name, place_full_name, place_type,country, location
FROM Twitter.dbo.Marvel
WHERE place_name IS NOT NULL OR
	  place_full_name IS NOT NULL OR
	  place_type IS NOT NULL OR
	  country IS NOT NULL OR
	  location IS NOT NULL;

--- The location for Marvel is given so we can keep it

ALTER TABLE Twitter.dbo.Marvel
DROP COLUMN place_name, place_full_name, place_type,
	 country;

-- user_id should be same since all these tweets are from DC comics
SELECT DISTINCT user_id, screen_name
FROM Twitter.dbo.DC

-- Inorder to reduce such redundancy, I will separate the user info into a separate table but still keep them in the
-- main table so that I make changes later if I need to

-- Creating a temp table
DROP TABLE IF EXISTS twitter_account_info
CREATE TABLE twitter_account_info
(
user_id varchar(10),
screen_name varchar(15),
friends_count numeric, -- Total number of accounts followed by the user
followers_count numeric, -- Total number of followers this account currently has
favourites_count numeric, -- The number of Tweets this user has liked in the account’s lifetime
status_count numeric, -- The number of Tweets (including retweets) issued by the user
account_creation Date -- The account creation date
)

-- Making sure there is no duplicate entry
-- Adding the account info into the table

INSERT INTO twitter_account_info
SELECT DISTINCT user_id, screen_name, friends_count, followers_count, favourites_count,statuses_count, CAST(account_created_at AS Date)
FROM Twitter.dbo.DC

INSERT INTO twitter_account_info
SELECT DISTINCT user_id, screen_name, friends_count, followers_count, favourites_count,statuses_count, CAST(account_created_at AS Date)
FROM Twitter.dbo.Marvel


SELECT *
FROM twitter_account_info

-- Time to check the tweets!

SELECT user_id,quote_count,reply_count
FROM Twitter.dbo.DC
WHERE	reply_count IS NOT NULL OR
	quote_count IS NOT NULL
UNION
SELECT user_id,quote_count,reply_count
FROM Twitter.dbo.Marvel
WHERE	reply_count IS NOT NULL OR
	quote_count IS NOT NULL

-- quote_count and reply_count for both are all NUll 

-- Checking the tweeting activity of Marvel and DC account
SELECT user_id, status_id,date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
FROM Twitter.dbo.DC
UNION 
SELECT user_id, status_id, date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
FROM Twitter.dbo.Marvel

-- Checking number of Marvel and DC per day

SELECT	T.date_of_tweet, info.screen_name, COUNT(T.date_of_tweet) AS 'Total number of tweets',
	ROUND(SUM(CAST(T.is_retweet AS INT)),2) AS 'Total number of retweet tweets', ROUND(SUM(CAST(T.is_quote AS INT)),2) AS 'Total number of quote tweets', 
	COUNT(T.date_of_tweet) - (ROUND(SUM(CAST(T.is_retweet AS INT)),2) + ROUND(SUM(CAST(T.is_quote AS INT)),2)) AS 'Original Tweets'
FROM (SELECT user_id, status_id,date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
FROM Twitter.dbo.DC
UNION 
SELECT user_id, status_id, date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
FROM Twitter.dbo.Marvel) AS T, twitter_account_info AS info
WHERE T.user_id = info.user_id
GROUP BY T.date_of_tweet, info.screen_name
ORDER BY date_of_tweet

-- It is hard to compare since the dates of the tweets for MArvel and DC are not same. So next, I will only consider tweets that were tweeted on the same day by Marvel and DC

-- The dates when both Marvel and DC tweeted

SELECT DISTINCT M.date_of_tweet
FROM Twitter.dbo.Marvel AS M, (SELECT user_id, status_id, date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
FROM Twitter.dbo.DC) AS D
WHERE M.date_of_tweet = D.date_of_tweet
ORDER BY date_of_tweet DESC


-- Temp view for visualization later

CREATE VIEW OriginalTweets AS
SELECT screen_name, date_of_tweet, COUNT(date_of_tweet) AS 'Total number of tweets',
	ROUND(SUM(CAST(is_retweet AS INT)),2) AS 'Total number of retweet tweets', ROUND(SUM(CAST(is_quote AS INT)),2) AS 'Total number of quote tweets', 
	COUNT(date_of_tweet) - (ROUND(SUM(CAST(is_retweet AS INT)),2) + ROUND(SUM(CAST(is_quote AS INT)),2)) AS 'Original Tweets'
FROM Twitter.dbo.DC
WHERE date_of_tweet in (SELECT DISTINCT M.date_of_tweet
FROM Twitter.dbo.Marvel AS M, (SELECT user_id, status_id, date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
FROM Twitter.dbo.DC) AS D
WHERE M.date_of_tweet = D.date_of_tweet)
GROUP BY date_of_tweet, screen_name
UNION
SELECT screen_name, date_of_tweet, COUNT(date_of_tweet) AS 'Total number of tweets',
	ROUND(SUM(CAST(is_retweet AS INT)),2) AS 'Total number of retweet tweets', ROUND(SUM(CAST(is_quote AS INT)),2) AS 'Total number of quote tweets', 
	COUNT(date_of_tweet) - (ROUND(SUM(CAST(is_retweet AS INT)),2) + ROUND(SUM(CAST(is_quote AS INT)),2)) AS 'Original Tweets'
FROM Twitter.dbo.Marvel
WHERE date_of_tweet in (SELECT DISTINCT M.date_of_tweet
FROM Twitter.dbo.Marvel AS M, (SELECT user_id, status_id, date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
FROM Twitter.dbo.DC) AS D
WHERE M.date_of_tweet = D.date_of_tweet)
GROUP BY date_of_tweet, screen_name

-- Now comparing the number of retweets and likes that DC and Marvel get during the same time frame

CREATE VIEW TweetLikesRetweets AS
SELECT screen_name,date_of_tweet, COUNT(date_of_tweet) AS 'Number of Tweets', ROUND(AVG(favorite_count),2) AS 'Avg likes for the day',
	ROUND(AVG(retweet_count),2) AS 'Avg retweets for the day'
FROM (SELECT screen_name, status_id,date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
	 FROM Twitter.dbo.DC
	 UNION 
	SELECT screen_name, status_id, date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
	FROM Twitter.dbo.Marvel) AS A
	WHERE date_of_tweet IN (SELECT DISTINCT M.date_of_tweet
	FROM Twitter.dbo.Marvel AS M, (SELECT screen_name, status_id, date_of_tweet, time_of_tweet, is_quote, is_retweet, favorite_count, retweet_count
	FROM Twitter.dbo.DC) AS D
WHERE M.date_of_tweet = D.date_of_tweet)
GROUP BY screen_name, date_of_tweet




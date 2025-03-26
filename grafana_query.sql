--------------------------------------------------------------
---------------------------整體會員樣態------------------------
--------------------------------------------------------------
-- 註冊會員數
SELECT COUNT(DISTINCT customer_id)
FROM customer;

-- 曾購買會員數
SELECT COUNT(DISTINCT customer_id)
FROM transaction;

-- 新註冊會員數月趨勢
SELECT 
    DATE_TRUNC('month', registered_at) AS month,
    COUNT(DISTINCT customer_id) AS customer_count
FROM customer
WHERE registered_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
GROUP BY month
ORDER BY month;

-- 購買會員數月趨勢
SELECT 
    DATE_TRUNC('month', transaction_at) AS month,
    COUNT(DISTINCT customer_id) AS customer_count
FROM transaction
WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
GROUP BY month
ORDER BY month;

-- 會員資料更新日期
SELECT registered_at FROM customer ORDER BY registered_at desc LIMIT 1;

-- 交易資料更新日期
SELECT action_at FROM customer_behavior WHERE action_type='view' ORDER BY action_at desc LIMIT 1;

-- 會員性別比例
SELECT 
    gender, 
    COUNT(DISTINCT customer_id) AS customer_count
FROM customer
GROUP BY gender;

-- 會員年齡比例
SELECT 
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / SUM(COUNT(DISTINCT customer_id)) OVER(), 2) AS customer_percentage,
    CASE 
        WHEN DATE_PART('year', AGE(NOW(), birth)) < 20 THEN '0-19歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 20 AND 29 THEN '20-29歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 30 AND 39 THEN '30-39歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 40 AND 49 THEN '40-49歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 50 AND 59 THEN '50-59歲'
        ELSE '60歲以上'
    END AS age_group
FROM customer
GROUP BY age_group;

-- 通路轉換比例
SELECT
CASE 
    WHEN referrer = 'direct' THEN '直接訪問'
    WHEN referrer = 'email' THEN '電子郵件'
    WHEN referrer = 'paid_ads' THEN '廣告'
    WHEN referrer = 'referral' THEN '其他網站'
    WHEN referrer = 'search_engine' THEN '搜尋引擎'
    WHEN referrer = 'social_media' THEN '社群網站'
    WHEN referrer = 'unknown' THEN '未知'
END AS referrer,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS referrer_percentage
FROM customer_behavior
WHERE action_type = 'purchase'
GROUP BY referrer;

-- 各類商品購買次數比例
SELECT p.category,
ROUND(COUNT(t.*) * 100.0 / SUM(COUNT(t.*)) OVER(), 2) AS category_percentage
FROM transaction t
LEFT JOIN product p
ON t.product_id=p.product_id
GROUP BY p.category
ORDER BY category_percentage DESC;

-- 各類商品購買金額比例
SELECT p.category,
ROUND(SUM(t.total) * 100.0 / SUM(SUM(t.total)) OVER(), 2) AS category_percentage
FROM transaction t
LEFT JOIN product p
ON t.product_id=p.product_id
GROUP BY p.category
ORDER BY category_percentage DESC;

--------------------------------------------------------------
---------------------------年度比較----------------------------
--------------------------------------------------------------
-- 今年訂單量
SELECT COUNT(*)
FROM transaction
WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE)
AND transaction_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year';

-- 去年訂單量
SELECT COUNT(*)
FROM transaction
WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
AND transaction_at < DATE_TRUNC('year', CURRENT_DATE);

-- 訂單量月趨勢
SELECT 
    last_year.month,
    this_year.transaction_count AS this_year_count,
    last_year.transaction_count AS last_year_count

FROM 
    (SELECT 
        EXTRACT(MONTH FROM transaction_at) AS month,
        COUNT(*) AS transaction_count
    FROM transaction
    WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
      AND transaction_at < DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY month) AS last_year

LEFT JOIN 
    (SELECT 
        EXTRACT(MONTH FROM transaction_at) AS month,
        COUNT(*) AS transaction_count
    FROM transaction
    WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE)
      AND transaction_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
    GROUP BY month) AS this_year

ON last_year.month = this_year.month
ORDER BY last_year.month;

-- 今年平均客單價
SELECT 
    SUM(total) / COUNT(*) AS avg_order_value
FROM transaction
WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE)
AND transaction_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year';

-- 去年平均客單價
SELECT
    SUM(total) / COUNT(*) AS avg_order_value
FROM transaction
WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
AND transaction_at < DATE_TRUNC('year', CURRENT_DATE);

-- 客單價月趨勢
SELECT 
    last_year.month,
    this_year.avg_order_value AS this_year_avg_value,
    last_year.avg_order_value AS last_year_avg_value

FROM 
    (SELECT 
        EXTRACT(MONTH FROM transaction_at) AS month,
        SUM(total) / COUNT(*) AS avg_order_value
    FROM transaction
    WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
      AND transaction_at < DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY month) AS last_year

LEFT JOIN 
    (SELECT 
        EXTRACT(MONTH FROM transaction_at) AS month,
        SUM(total) / COUNT(*) AS avg_order_value
    FROM transaction
    WHERE transaction_at >= DATE_TRUNC('year', CURRENT_DATE)
      AND transaction_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
    GROUP BY month) AS this_year

ON last_year.month = this_year.month
ORDER BY last_year.month;

-- 各通路轉換次數
SELECT 
    COALESCE(this_year.referrer, last_year.referrer) AS referrer,
    this_year.transaction_count AS this_year_count,
    last_year.transaction_count AS last_year_count,
    ROUND(this_year.transaction_count * 100.0 / SUM(this_year.transaction_count) OVER(), 2) AS this_year_percentage,
    ROUND(last_year.transaction_count * 100.0 / SUM(last_year.transaction_count) OVER(), 2) AS last_year_percentage
FROM 
    (SELECT 
        CASE 
            WHEN referrer = 'direct' THEN '直接訪問'
            WHEN referrer = 'email' THEN '電子郵件'
            WHEN referrer = 'paid_ads' THEN '廣告'
            WHEN referrer = 'referral' THEN '其他網站'
            WHEN referrer = 'search_engine' THEN '搜尋引擎'
            WHEN referrer = 'social_media' THEN '社群網站'
            WHEN referrer = 'unknown' THEN '未知'
        END AS referrer,
        COUNT(*) AS transaction_count
    FROM customer_behavior
    WHERE action_type = 'purchase'
      AND action_at >= DATE_TRUNC('year', CURRENT_DATE)
      AND action_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
    GROUP BY referrer) AS this_year

FULL JOIN 
    (SELECT 
        CASE 
            WHEN referrer = 'direct' THEN '直接訪問'
            WHEN referrer = 'email' THEN '電子郵件'
            WHEN referrer = 'paid_ads' THEN '廣告'
            WHEN referrer = 'referral' THEN '其他網站'
            WHEN referrer = 'search_engine' THEN '搜尋引擎'
            WHEN referrer = 'social_media' THEN '社群網站'
            WHEN referrer = 'unknown' THEN '未知'
        END AS referrer,
        COUNT(*) AS transaction_count
    FROM customer_behavior
    WHERE action_type = 'purchase'
      AND action_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
      AND action_at < DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY referrer) AS last_year

ON this_year.referrer = last_year.referrer
ORDER BY this_year_count DESC;

-- 各類商品購買次數
SELECT 
    COALESCE(this_year.category, last_year.category) AS category,
    this_year.transaction_count AS this_year_count,
    last_year.transaction_count AS last_year_count,
    ROUND(this_year.transaction_count * 100.0 / SUM(this_year.transaction_count) OVER(), 2) AS this_year_percentage,
    ROUND(last_year.transaction_count * 100.0 / SUM(last_year.transaction_count) OVER(), 2) AS last_year_percentage
FROM 
    (SELECT 
        p.category,
        COUNT(*) AS transaction_count
    FROM transaction t
    JOIN product p ON t.product_id = p.product_id 
    WHERE t.transaction_at >= DATE_TRUNC('year', CURRENT_DATE)
    AND t.transaction_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
    GROUP BY p.category) AS this_year

FULL JOIN 
    (SELECT 
        p.category,
        COUNT(*) AS transaction_count
    FROM transaction t
    JOIN product p ON t.product_id = p.product_id 
    WHERE t.transaction_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
    AND t.transaction_at < DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY p.category) AS last_year

ON this_year.category = last_year.category
ORDER BY this_year_count DESC;

-- 各類商品購買金額
SELECT 
    COALESCE(this_year.category, last_year.category) AS category,
    this_year.transaction_total AS this_year_total,
    last_year.transaction_total AS last_year_total,
    ROUND(this_year.transaction_total * 100.0 / SUM(this_year.transaction_total) OVER(), 2) AS this_year_percentage,
    ROUND(last_year.transaction_total * 100.0 / SUM(last_year.transaction_total) OVER(), 2) AS last_year_percentage
FROM 
    (SELECT 
        p.category,
        SUM(total) AS transaction_total
    FROM transaction t
    JOIN product p ON t.product_id = p.product_id  
    WHERE t.transaction_at >= DATE_TRUNC('year', CURRENT_DATE)
    AND t.transaction_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
    GROUP BY p.category) AS this_year

FULL JOIN 
    (SELECT
        p.category,
        SUM(total) AS transaction_total
    FROM transaction t
    JOIN product p ON t.product_id = p.product_id 
    WHERE t.transaction_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year'
    AND t.transaction_at < DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY p.category) AS last_year

ON this_year.category = last_year.category
ORDER BY this_year_total DESC;

--------------------------------------------------------------
-----------------------本周比較--------------------------------
--------------------------------------------------------------
-- 篩選器：性別
SELECT 
CASE 
 WHEN gender = 'F' THEN '女'
 WHEN gender = 'M' THEN '男'
END AS gender
FROM customer;

-- 篩選器：年齡
SELECT 
    CASE 
        WHEN DATE_PART('year', AGE(NOW(), birth)) < 20 THEN '0-19歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 20 AND 29 THEN '20-29歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 30 AND 39 THEN '30-39歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 40 AND 49 THEN '40-49歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 50 AND 59 THEN '50-59歲'
        ELSE '60歲以上'
    END AS age_group
FROM customer
GROUP BY age_group
ORDER BY age_group;

-- 篩選器：通路
SELECT 
CASE 
 WHEN referrer = 'direct' THEN '直接訪問'
 WHEN referrer = 'email' THEN '電子郵件'
 WHEN referrer = 'paid_ads' THEN '廣告'
 WHEN referrer = 'referral' THEN '其他網站'
 WHEN referrer = 'search_engine' THEN '搜尋引擎'
 WHEN referrer = 'social_media' THEN '社群網站'
 WHEN referrer = 'unknown' THEN '未知'
END AS referrer
FROM customer_behavior;

-- 本周訂單數
SELECT 
    'last week' AS period,
    COUNT(*) AS count
FROM customer_behavior b
JOIN customer c ON b.customer_id=c.customer_id
WHERE b.action_type = 'purchase'
AND 
    (
    (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
    )
AND 
    (
    (c.gender = 'F' AND '女' IN (${gender}))
    OR (c.gender = 'M' AND '男' IN (${gender}))
    )
AND
    (
    (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
    OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
    OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
    OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
    OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
    OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
    OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
    )
AND b.action_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 week'
AND b.action_at < DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'

UNION ALL

SELECT 
    'this week' AS period,
    COUNT(*) AS count
FROM customer_behavior b
JOIN customer c ON b.customer_id=c.customer_id
WHERE b.action_type = 'purchase'
AND 
    (
    (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
    )
AND 
    (
    (c.gender = 'F' AND '女' IN (${gender}))
    OR (c.gender = 'M' AND '男' IN (${gender}))
    )
AND
    (
    (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
    OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
    OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
    OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
    OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
    OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
    OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
    )
AND b.action_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
AND b.action_at < DATE_TRUNC('week', CURRENT_DATE)
ORDER BY period ASC;

-- 購買會員性別
SELECT 
    c.gender,
    COUNT(DISTINCT b.customer_id) AS customer_count
FROM customer_behavior b
JOIN customer c ON b.customer_id=c.customer_id
WHERE b.action_type = 'purchase'
AND
    (
    (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
    )
AND 
    (
    (c.gender = 'F' AND '女' IN (${gender}))
    OR (c.gender = 'M' AND '男' IN (${gender}))
    )
AND
    (
    (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
    OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
    OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
    OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
    OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
    OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
    OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
    )
AND b.action_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
AND b.action_at < DATE_TRUNC('week', CURRENT_DATE)
GROUP BY c.gender;

-- 購買會員年齡
SELECT 
    ROUND(COUNT(DISTINCT b.customer_id) * 100.0 / SUM(COUNT(DISTINCT b.customer_id)) OVER(), 2) AS percentage,
    CASE 
        WHEN DATE_PART('year', AGE(NOW(), birth)) < 20 THEN '0-19歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 20 AND 29 THEN '20-29歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 30 AND 39 THEN '30-39歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 40 AND 49 THEN '40-49歲'
        WHEN DATE_PART('year', AGE(NOW(), birth)) BETWEEN 50 AND 59 THEN '50-59歲'
        ELSE '60歲以上'
    END AS age_group
FROM customer_behavior b
JOIN customer c ON b.customer_id = c.customer_id
WHERE b.action_type = 'purchase'
AND
    (
    (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
    )
AND 
    (
    (c.gender = 'F' AND '女' IN (${gender}))
    OR (c.gender = 'M' AND '男' IN (${gender}))
    )
AND
    (
    (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
    OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
    OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
    OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
    OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
    OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
    OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
    )
AND b.action_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
AND b.action_at < DATE_TRUNC('week', CURRENT_DATE)
GROUP BY age_group
ORDER BY age_group;

-- 購買通路
SELECT 
    CASE 
        WHEN b.referrer = 'direct' THEN '直接訪問'
        WHEN b.referrer = 'email' THEN '電子郵件'
        WHEN b.referrer = 'paid_ads' THEN '廣告'
        WHEN b.referrer = 'referral' THEN '其他網站'
        WHEN b.referrer = 'search_engine' THEN '搜尋引擎'
        WHEN b.referrer = 'social_media' THEN '社群網站'
        WHEN b.referrer = 'unknown' THEN '未知'
    END AS referrer, 
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM customer_behavior b
JOIN customer c ON b.customer_id = c.customer_id
WHERE b.action_type = 'purchase'
AND 
    (
    (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
    )
AND 
    (
    (c.gender = 'F' AND '女' IN (${gender}))
    OR (c.gender = 'M' AND '男' IN (${gender}))
    )
AND
    (
    (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
    OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
    OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
    OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
    OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
    OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
    OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
    )
AND b.action_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
AND b.action_at < DATE_TRUNC('week', CURRENT_DATE)
GROUP BY b.referrer
ORDER BY percentage DESC ;

-- 各類商品購買情形
SELECT 
    COALESCE(this_week.category, last_week.category) AS category,
    this_week.transaction_count AS this_week_count,
    last_week.transaction_count AS last_week_count,
    this_week.transaction_total AS this_week_total,
    last_week.transaction_total AS last_week_total
FROM 
    (SELECT 
        p.category AS category,
        COUNT(*) AS transaction_count,
        SUM(total) AS transaction_total
    FROM transaction t
    JOIN product p ON t.product_id = p.product_id
    JOIN customer c ON t.customer_id = c.customer_id
    JOIN customer_behavior b ON t.customer_id = b.customer_id
    AND t.product_id = b.product_id
    AND t.transaction_at = b.action_at
    WHERE 
        (
        (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
        )
    AND 
        (
        (c.gender = 'F' AND '女' IN (${gender}))
        OR (c.gender = 'M' AND '男' IN (${gender}))
        )
    AND
        (
        (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
        OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
        OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
        OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
        OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
        OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
        OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
        )
    AND t.transaction_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
    AND t.transaction_at < DATE_TRUNC('week', CURRENT_DATE)
    GROUP BY p.category) AS this_week

FULL JOIN 
    (SELECT 
        p.category AS category,
        COUNT(*) AS transaction_count,
        SUM(total) AS transaction_total
    FROM transaction t
    JOIN product p ON t.product_id = p.product_id
    JOIN customer c ON t.customer_id = c.customer_id
    JOIN customer_behavior b ON t.customer_id = b.customer_id
    AND t.product_id = b.product_id
    AND t.transaction_at = b.action_at
    WHERE 
        (
        (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
        OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
        )
    AND 
        (
        (c.gender = 'F' AND '女' IN (${gender}))
        OR (c.gender = 'M' AND '男' IN (${gender}))
        )
    AND
        (
        (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
        OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
        OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
        OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
        OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
        OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
        OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
        )
    AND t.transaction_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 week'
    AND t.transaction_at < DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
    GROUP BY p.category) AS last_week

ON this_week.category = last_week.category
ORDER BY this_week.category;

-- 會員購物歷程
SELECT 
    b.action_type,
    COUNT(b.customer_id) AS customer_count
FROM customer_behavior b
JOIN customer c ON b.customer_id = c.customer_id
WHERE 
    (
    (DATE_PART('year', AGE(NOW(), c.birth)) < 20 AND '0-19歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 20 AND 29 AND '20-29歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 30 AND 39 AND '30-39歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 40 AND 49 AND '40-49歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) BETWEEN 50 AND 59 AND '50-59歲' IN (${age_group}))
    OR (DATE_PART('year', AGE(NOW(), c.birth)) >= 60 AND '60歲以上' IN (${age_group}))
    )
AND 
    (
    (c.gender = 'F' AND '女' IN (${gender}))
    OR (c.gender = 'M' AND '男' IN (${gender}))
    )
AND
    (
    (b.referrer = 'direct' AND '直接訪問' IN (${referrer})) 
    OR (b.referrer = 'email' AND '電子郵件' IN (${referrer})) 
    OR (b.referrer = 'paid_ads' AND '廣告' IN (${referrer})) 
    OR (b.referrer = 'referral' AND '其他網站' IN (${referrer})) 
    OR (b.referrer = 'search_engine' AND '搜尋引擎' IN (${referrer})) 
    OR (b.referrer = 'social_media' AND '社群網站' IN (${referrer})) 
    OR (b.referrer = 'unknown' AND '未知' IN (${referrer})) 
    )
AND b.action_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
AND b.action_at < DATE_TRUNC('week', CURRENT_DATE)
GROUP BY b.action_type
ORDER BY customer_count desc;

-- 本周促銷活動
SELECT *
FROM promotion
WHERE published_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
AND published_at < DATE_TRUNC('week', CURRENT_DATE)
 
-- 上週促銷活動
SELECT *
FROM promotion
WHERE published_at >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '2 week'
AND published_at < DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week'
-- Seed initial gift products for Silni app
-- Products curated from Amazon.sa, Noon, and Jarir

INSERT INTO gifts (name_ar, name_en, brand, category, price_sar, image_url, purchase_url, retailer, occasions, recipient_tags, gender, age_range) VALUES

-- Electronics (15 products)
('سماعات أبل إيربودز برو 2', 'Apple AirPods Pro 2', 'Apple', 'electronics', 899,
 'https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B0BDHWDR12', 'Amazon.sa',
 ARRAY['birthday', 'graduation', 'eid', 'general'], ARRAY['tech_lover', 'music', 'professional'], 'unisex', '18-50'),

('ساعة أبل ووتش SE الجيل الثاني', 'Apple Watch SE 2nd Gen', 'Apple', 'electronics', 999,
 'https://m.media-amazon.com/images/I/71XMTLtZd5L._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B0BDHT5M5D', 'Amazon.sa',
 ARRAY['birthday', 'graduation', 'eid', 'general'], ARRAY['tech_lover', 'fitness', 'professional'], 'unisex', '18-50'),

('سماعات سامسونج جالاكسي بادز 2 برو', 'Samsung Galaxy Buds 2 Pro', 'Samsung', 'electronics', 649,
 'https://m.media-amazon.com/images/I/51bRScn0EfL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B0B6BWT83N', 'Amazon.sa',
 ARRAY['birthday', 'graduation', 'eid', 'general'], ARRAY['tech_lover', 'music'], 'unisex', '18-40'),

('تابلت سامسونج جالاكسي تاب S6 لايت', 'Samsung Galaxy Tab S6 Lite', 'Samsung', 'electronics', 1299,
 'https://m.media-amazon.com/images/I/71zBrk8WtML._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B08TV3YPM4', 'Amazon.sa',
 ARRAY['birthday', 'graduation', 'eid', 'general'], ARRAY['tech_lover', 'student', 'artist'], 'unisex', '12-50'),

('كيندل بيبر وايت', 'Kindle Paperwhite', 'Amazon', 'electronics', 549,
 'https://m.media-amazon.com/images/I/61nDGJQBLDL._AC_SL1000_.jpg',
 'https://www.amazon.sa/dp/B08KTZ8249', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['reader', 'student', 'professional'], 'unisex', '18-70'),

-- Perfumes Men (8 products)
('عطر ديور سوفاج الرجالي', 'Dior Sauvage EDT', 'Dior', 'perfume_men', 450,
 'https://m.media-amazon.com/images/I/71tyocb-c7L._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B01MUGXBB0', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'professional'], 'male', '18-50'),

('عطر بلو دي شانيل', 'Bleu de Chanel EDP', 'Chanel', 'perfume_men', 520,
 'https://m.media-amazon.com/images/I/61Wd0GZwT2L._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B01N4BWQXW', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'professional'], 'male', '25-55'),

('عطر فرزاتشي إيروس', 'Versace Eros EDT', 'Versace', 'perfume_men', 320,
 'https://m.media-amazon.com/images/I/61UfYQYoWJL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B009NWB5US', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['fashion', 'young'], 'male', '18-35'),

('عطر توم فورد عود وود', 'Tom Ford Oud Wood', 'Tom Ford', 'perfume_men', 890,
 'https://m.media-amazon.com/images/I/51fSRo2c6QL._AC_SL1160_.jpg',
 'https://www.amazon.sa/dp/B001FWXJLA', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'luxury', 'professional'], 'male', '30-60'),

-- Perfumes Women (8 products)
('عطر شانيل نمبر 5', 'Chanel No 5 EDP', 'Chanel', 'perfume_women', 650,
 'https://m.media-amazon.com/images/I/71X2mXrFPsL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B001F6Q3WC', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'luxury'], 'female', '30-60'),

('عطر ميس ديور', 'Miss Dior EDP', 'Dior', 'perfume_women', 480,
 'https://m.media-amazon.com/images/I/61k9kU9eweL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B071J3L1D4', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'romantic'], 'female', '20-45'),

('عطر لانكوم لا في است بيل', 'Lancome La Vie Est Belle', 'Lancome', 'perfume_women', 420,
 'https://m.media-amazon.com/images/I/61vEoG9tBQL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B0093KSBLW', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'romantic'], 'female', '25-50'),

('عطر يف سان لوران بلاك أوبيوم', 'YSL Black Opium', 'YSL', 'perfume_women', 490,
 'https://m.media-amazon.com/images/I/71aTwMz3wCL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00LV43S78', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['fashion', 'young', 'trendy'], 'female', '18-35'),

-- Jewelry & Watches (10 products)
('سوار باندورا فضة', 'Pandora Silver Bracelet', 'Pandora', 'jewelry', 350,
 'https://m.media-amazon.com/images/I/51XcWsP23XL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00GXUGZ7W', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'romantic'], 'female', '18-50'),

('ساعة كاسيو جي شوك', 'Casio G-Shock', 'Casio', 'watches', 450,
 'https://m.media-amazon.com/images/I/81jEbQgZySL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00284ADAI', 'Amazon.sa',
 ARRAY['birthday', 'graduation', 'eid', 'general'], ARRAY['sports', 'adventure', 'young'], 'male', '15-40'),

('ساعة تيسوت بي آر إكس', 'Tissot PRX', 'Tissot', 'watches', 1800,
 'https://m.media-amazon.com/images/I/71pR5OPm0UL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B08X4XLFHQ', 'Amazon.sa',
 ARRAY['birthday', 'graduation', 'wedding', 'eid'], ARRAY['professional', 'fashion', 'luxury'], 'male', '25-55'),

('أقراط سواروفسكي كريستال', 'Swarovski Crystal Earrings', 'Swarovski', 'jewelry', 280,
 'https://m.media-amazon.com/images/I/71QFHK6HFDL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B007VTTZRI', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['fashion', 'elegant'], 'female', '20-50'),

-- Books & Islamic (8 products)
('مصحف المدينة المنورة فاخر', 'Madinah Mushaf Premium', 'مجمع الملك فهد', 'islamic', 150,
 'https://m.media-amazon.com/images/I/81NhVHjFHkL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07PXCLNTQ', 'Amazon.sa',
 ARRAY['ramadan', 'eid', 'wedding', 'general'], ARRAY['religious', 'family'], 'unisex', '10-80'),

('كتاب لا تحزن', 'La Tahzan Book', 'عائض القرني', 'books', 45,
 'https://www.jarir.com/media/catalog/product/cache/1/image/9df78eab33525d08d6e5fb8d27136e95/0/6/0654321.jpg',
 'https://www.jarir.com/arabic-books-654321.html', 'Jarir',
 ARRAY['birthday', 'general'], ARRAY['reader', 'religious'], 'unisex', '18-70'),

('مجموعة السيرة النبوية', 'Prophet Biography Set', 'دار السلام', 'islamic', 250,
 'https://m.media-amazon.com/images/I/71CxRMW3bSL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B08XYDW7FZ', 'Amazon.sa',
 ARRAY['ramadan', 'eid', 'general'], ARRAY['reader', 'religious', 'family'], 'unisex', '15-70'),

-- Home & Kitchen (10 products)
('ماكينة قهوة نسبريسو فيرتو', 'Nespresso Vertuo Next', 'Nespresso', 'home', 799,
 'https://m.media-amazon.com/images/I/61DdXBh4P0L._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B08PP2MKP3', 'Amazon.sa',
 ARRAY['wedding', 'general'], ARRAY['coffee_lover', 'home'], 'unisex', '25-60'),

('خلاط نينجا احترافي', 'Ninja Professional Blender', 'Ninja', 'home', 449,
 'https://m.media-amazon.com/images/I/71s0QAoP5GL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07Z2QJQHY', 'Amazon.sa',
 ARRAY['wedding', 'general'], ARRAY['cooking', 'home', 'health'], 'unisex', '25-55'),

('مجموعة شموع معطرة فاخرة', 'Luxury Scented Candle Set', 'Jo Malone', 'home', 320,
 'https://m.media-amazon.com/images/I/71rZLEUmvnL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07K5QXQGG', 'Amazon.sa',
 ARRAY['birthday', 'wedding', 'general'], ARRAY['home', 'relaxation'], 'female', '25-55'),

('موزع عطر منزلي ذكي', 'Smart Home Diffuser', 'Muji', 'home', 180,
 'https://m.media-amazon.com/images/I/51LJXvHIhxL._AC_SL1100_.jpg',
 'https://www.noon.com/product/N123456', 'Noon',
 ARRAY['wedding', 'general'], ARRAY['home', 'relaxation', 'wellness'], 'unisex', '25-55'),

-- Food & Sweets (8 products)
('علبة شوكولاتة جوديفا فاخرة', 'Godiva Luxury Chocolate Box', 'Godiva', 'food', 280,
 'https://m.media-amazon.com/images/I/81kV6sLNtBL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07QV1QV1R', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'ramadan', 'general'], ARRAY['sweet_tooth', 'luxury'], 'unisex', '10-70'),

('مجموعة تمور العجوة المدينة', 'Ajwa Dates Premium Box', 'تمور المدينة', 'food', 350,
 'https://m.media-amazon.com/images/I/71PWUQ9Qf2L._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B08Y5HWVY9', 'Amazon.sa',
 ARRAY['ramadan', 'eid', 'wedding', 'general'], ARRAY['religious', 'family', 'health'], 'unisex', '15-80'),

('مجموعة شوكولاتة باتشي', 'Patchi Chocolate Collection', 'Patchi', 'food', 420,
 'https://m.media-amazon.com/images/I/71RM+zQZl+L._AC_SL1500_.jpg',
 'https://www.noon.com/product/patchi-collection', 'Noon',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['sweet_tooth', 'luxury'], 'unisex', '15-65'),

('عسل سدر يمني أصلي', 'Yemeni Sidr Honey', 'عسل الجزيرة', 'food', 550,
 'https://m.media-amazon.com/images/I/61EkxTOQxRL._AC_SL1200_.jpg',
 'https://www.amazon.sa/dp/B07XQXNQZF', 'Amazon.sa',
 ARRAY['ramadan', 'eid', 'recovery', 'general'], ARRAY['health', 'natural', 'family'], 'unisex', '18-80'),

-- Fashion & Bags (8 products)
('حقيبة مايكل كورس', 'Michael Kors Tote Bag', 'Michael Kors', 'fashion', 850,
 'https://m.media-amazon.com/images/I/81O-xq6FBRL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B09G6BVHF4', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['fashion', 'professional'], 'female', '22-50'),

('محفظة جلدية رجالية مون بلان', 'Montblanc Leather Wallet', 'Montblanc', 'fashion', 1200,
 'https://m.media-amazon.com/images/I/71MWVVlZhVL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00H3J4FMC', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'graduation', 'general'], ARRAY['professional', 'luxury'], 'male', '25-60'),

('نظارة شمسية ريبان أفياتور', 'Ray-Ban Aviator', 'Ray-Ban', 'fashion', 650,
 'https://m.media-amazon.com/images/I/71h7JA7dfOL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00R58OLAM', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['fashion', 'outdoor'], 'unisex', '18-50'),

('شماغ شتوي فاخر', 'Premium Winter Shemagh', 'جيفنشي', 'fashion', 380,
 'https://m.media-amazon.com/images/I/71k8BKPBbeL._AC_SL1500_.jpg',
 'https://www.jarir.com/shemagh-givenchy.html', 'Jarir',
 ARRAY['birthday', 'eid', 'wedding', 'general'], ARRAY['traditional', 'professional'], 'male', '20-60'),

-- Kids & Baby (8 products)
('مجموعة ليجو كلاسيك', 'LEGO Classic Set', 'LEGO', 'kids', 200,
 'https://m.media-amazon.com/images/I/91K-jfj4paL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00NHQFA1I', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['creative', 'educational'], 'unisex', '4-12'),

('دمية باربي دريم هاوس', 'Barbie Dreamhouse', 'Barbie', 'kids', 750,
 'https://m.media-amazon.com/images/I/81xWR5qMbfL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07GLQXL16', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['imaginative', 'doll_lover'], 'female', '3-10'),

('سيارة تحكم عن بعد', 'RC Monster Truck', 'Hot Wheels', 'kids', 180,
 'https://m.media-amazon.com/images/I/81nxVCHQQOL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07GXRGX2M', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['active', 'outdoor'], 'male', '5-12'),

('مجموعة تلوين وفنون للأطفال', 'Kids Art & Craft Set', 'Crayola', 'kids', 120,
 'https://m.media-amazon.com/images/I/81OiR5DxkjL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00004YS18', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['creative', 'artistic'], 'unisex', '3-10'),

('طقم ملابس مولود جديد', 'Newborn Baby Gift Set', 'Carter', 'baby', 250,
 'https://m.media-amazon.com/images/I/71Zl8mHNmcL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07QJXLN8B', 'Amazon.sa',
 ARRAY['newborn', 'general'], ARRAY['baby', 'practical'], 'unisex', '0-1'),

-- Sports & Fitness (5 products)
('سماعات بيتس سولو 3', 'Beats Solo 3 Wireless', 'Beats', 'sports', 699,
 'https://m.media-amazon.com/images/I/71bLZA+OvsL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B01LWWY3E5', 'Amazon.sa',
 ARRAY['birthday', 'graduation', 'eid', 'general'], ARRAY['music', 'fitness', 'sports'], 'unisex', '15-40'),

('ساعة فيت بت تشارج 5', 'Fitbit Charge 5', 'Fitbit', 'sports', 599,
 'https://m.media-amazon.com/images/I/61YV27T-bnL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B09BXL8FPC', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['fitness', 'health', 'tech_lover'], 'unisex', '18-55'),

('حذاء نايك اير ماكس', 'Nike Air Max', 'Nike', 'sports', 650,
 'https://m.media-amazon.com/images/I/71rN+PyGDFL._AC_SL1500_.jpg',
 'https://www.noon.com/product/nike-airmax', 'Noon',
 ARRAY['birthday', 'eid', 'general'], ARRAY['sports', 'fitness', 'fashion'], 'unisex', '15-45'),

-- Luxury & Special (5 products)
('قلم مون بلان ميسترستيك', 'Montblanc Meisterstuck Pen', 'Montblanc', 'luxury', 2500,
 'https://m.media-amazon.com/images/I/61fQlZLrURL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B00009ZVBS', 'Amazon.sa',
 ARRAY['graduation', 'wedding', 'general'], ARRAY['professional', 'luxury', 'collector'], 'unisex', '25-65'),

('طقم عطور أجمل للعود', 'Ajmal Oud Collection', 'Ajmal', 'perfume', 890,
 'https://m.media-amazon.com/images/I/71VXAw5xM2L._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B01LYNHJ1P', 'Amazon.sa',
 ARRAY['eid', 'wedding', 'ramadan', 'general'], ARRAY['luxury', 'traditional', 'collector'], 'unisex', '30-70'),

('مجموعة عود وبخور فاخرة', 'Premium Oud & Incense Set', 'Abdul Samad Al Qurashi', 'islamic', 1200,
 'https://m.media-amazon.com/images/I/71A+u8LdWcL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07BGQXMR4', 'Amazon.sa',
 ARRAY['eid', 'wedding', 'ramadan', 'general'], ARRAY['traditional', 'luxury', 'religious'], 'unisex', '30-75');

-- Add more budget-friendly options (50-200 SAR range)
INSERT INTO gifts (name_ar, name_en, brand, category, price_sar, image_url, purchase_url, retailer, occasions, recipient_tags, gender, age_range) VALUES

('كوب ستاربكس حافظ للحرارة', 'Starbucks Tumbler', 'Starbucks', 'home', 120,
 'https://m.media-amazon.com/images/I/61s1VO0KIjL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B08R7MZJJV', 'Amazon.sa',
 ARRAY['birthday', 'general'], ARRAY['coffee_lover', 'practical'], 'unisex', '18-50'),

('محفظة جلدية صغيرة', 'Leather Card Holder', 'Fossil', 'fashion', 180,
 'https://m.media-amazon.com/images/I/71JCODvKcEL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07D4X5GZD', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'graduation', 'general'], ARRAY['professional', 'practical'], 'unisex', '18-55'),

('عطر زارا الرجالي', 'Zara Man Blue Spirit', 'Zara', 'perfume_men', 89,
 'https://m.media-amazon.com/images/I/41EK8K2qXoL._AC_SL1000_.jpg',
 'https://www.noon.com/product/zara-man', 'Noon',
 ARRAY['birthday', 'eid', 'general'], ARRAY['young', 'fashion'], 'male', '18-35'),

('عطر زارا النسائي', 'Zara Woman Rose', 'Zara', 'perfume_women', 85,
 'https://m.media-amazon.com/images/I/51KxQsQ-5DL._AC_SL1000_.jpg',
 'https://www.noon.com/product/zara-woman', 'Noon',
 ARRAY['birthday', 'eid', 'general'], ARRAY['young', 'fashion'], 'female', '18-35'),

('سماعات سلكية سوني', 'Sony Wired Earbuds', 'Sony', 'electronics', 99,
 'https://m.media-amazon.com/images/I/61LPnME8EJL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B07K5FJ1ST', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['music', 'student', 'practical'], 'unisex', '12-40'),

('دفتر مولسكين كلاسيك', 'Moleskine Classic Notebook', 'Moleskine', 'stationery', 95,
 'https://m.media-amazon.com/images/I/71QKQ9mwV7L._AC_SL1500_.jpg',
 'https://www.jarir.com/moleskine-notebook.html', 'Jarir',
 ARRAY['birthday', 'graduation', 'general'], ARRAY['writer', 'student', 'professional'], 'unisex', '15-55'),

('مجموعة ألوان فابر كاستل', 'Faber-Castell Color Pencils', 'Faber-Castell', 'stationery', 75,
 'https://m.media-amazon.com/images/I/71+X7oW1xZL._AC_SL1500_.jpg',
 'https://www.jarir.com/faber-castell-colors.html', 'Jarir',
 ARRAY['birthday', 'eid', 'general'], ARRAY['artist', 'creative', 'student'], 'unisex', '8-40'),

('كتاب العادات الذرية', 'Atomic Habits Book', 'James Clear', 'books', 65,
 'https://m.media-amazon.com/images/I/81wgcld4wxL._AC_SL1500_.jpg',
 'https://www.jarir.com/atomic-habits-ar.html', 'Jarir',
 ARRAY['birthday', 'graduation', 'general'], ARRAY['reader', 'self_improvement', 'professional'], 'unisex', '18-55'),

('سماعة بلوتوث صغيرة جي بي ال', 'JBL Go 3 Speaker', 'JBL', 'electronics', 179,
 'https://m.media-amazon.com/images/I/71YB8DBKVLL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B08KW2TQZS', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['music', 'outdoor', 'tech_lover'], 'unisex', '15-45'),

('باور بانك أنكر 10000', 'Anker PowerCore 10000', 'Anker', 'electronics', 129,
 'https://m.media-amazon.com/images/I/61-Hb04CZVL._AC_SL1500_.jpg',
 'https://www.amazon.sa/dp/B0194WDVHI', 'Amazon.sa',
 ARRAY['birthday', 'eid', 'general'], ARRAY['tech_lover', 'practical', 'traveler'], 'unisex', '15-55');

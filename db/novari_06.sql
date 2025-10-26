/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.13-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: novari_06
-- ------------------------------------------------------
-- Server version	10.11.13-MariaDB-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alembic_version`
--

DROP TABLE IF EXISTS `alembic_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alembic_version`
--

LOCK TABLES `alembic_version` WRITE;
/*!40000 ALTER TABLE `alembic_version` DISABLE KEYS */;
INSERT INTO `alembic_version` VALUES
('cac42b090f65');
/*!40000 ALTER TABLE `alembic_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cart`
--

DROP TABLE IF EXISTS `cart`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart` (
  `cartID` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `size_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `added_at` datetime DEFAULT NULL,
  PRIMARY KEY (`cartID`),
  KEY `customer_id` (`customer_id`),
  KEY `product_id` (`product_id`),
  KEY `size_id` (`size_id`),
  CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`pID`),
  CONSTRAINT `cart_ibfk_3` FOREIGN KEY (`size_id`) REFERENCES `product_sizes` (`sizeID`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cart`
--

LOCK TABLES `cart` WRITE;
/*!40000 ALTER TABLE `cart` DISABLE KEYS */;
INSERT INTO `cart` VALUES
(15,17,25,28,1,'2025-05-08 09:51:37');
/*!40000 ALTER TABLE `cart` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `catID` int(11) NOT NULL AUTO_INCREMENT,
  `catName` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  PRIMARY KEY (`catID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categories`
--

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES
(6,'HOODIES','HOODIES'),
(7,'JACKETS','JACKETS'),
(8,'CREWNECKS','CREWNECKS'),
(9,'PANTS','PANTS');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer`
--

DROP TABLE IF EXISTS `customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(100) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `password_hash` varchar(256) DEFAULT NULL,
  `date_joined` datetime DEFAULT NULL,
  `is_admin` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer`
--

LOCK TABLES `customer` WRITE;
/*!40000 ALTER TABLE `customer` DISABLE KEYS */;
INSERT INTO `customer` VALUES
(11,'admin@gmail.com','admin','scrypt:32768:8:1$1ALJnTr5gYjzLHee$06f4aced4a01f442f866ec9d4159d6ed286668cc99ec05b04a67eb772c64d8956bd5ea53833dace24c50f022659a0ed959047a1ef2685a9eb8fbe10c33473614','2025-04-15 01:21:22',NULL),
(12,'yasseen@gmail.com','yasseen','scrypt:32768:8:1$GEiqLcsGSpOADS7z$1dbe25cb73e7d7d4355782cc619d6a5d31f7c2d5cc2da1a68f25f1239a725f2ff0da968159588ecb89d8f112d655df076082c4f678bbbde1b87a7ccdf2173fd6','2025-04-16 00:47:45',NULL),
(13,'epeterson6@sc.rr.com','yasseen','scrypt:32768:8:1$6wIvSSNxhO5DyYWR$76811e1935797e73a8b42d0eaa358695b16a617d0640b57876a0dac682514247040e2768758c8b55818a5c41afc5b5ea378b56a8cc580f3ad8f6b9a6414c6e4c','2025-04-16 00:47:59',NULL),
(14,'3bf7b9b729@emailawb.pro','yasseen','scrypt:32768:8:1$EVd2dyUu1kOyFBco$55be7515dac427e90a3b8e437346c2fc850bdf3d397ae639ea4509c4341a807662186b0235ea1e8d5a89234a9e9457c6fa7a24e60b999537a2be3f4f2a966985','2025-04-16 00:48:07',NULL),
(15,'mahmoud@gmail.com','mahmoud','scrypt:32768:8:1$Ectj6YVuzZOYghmT$5fb49a41fe77fb1390f9dc700dca9558e583fabf5f5da84276dc37a370618e105886358e61a61174cf47c0f94857cf3c36ef75d96666d4048a19e9a623b113cf','2025-04-16 00:48:32',NULL),
(16,'mahmoudtarekk07@gmail.com','mahmoudtarekk07@gmail.com','scrypt:32768:8:1$XvPPSvbY2cc6yLOQ$4f8f8ca98743a319403b4a7d25cd6172f2b8d350e22f985d44d12ebe86ec257f7a32471ab8045d3cc9aac09dfab72fd6093c5e7fd8aab2f1f7b84cfd6c336b8f','2025-05-07 17:28:49',NULL),
(17,'any@gmail.com','anyone','scrypt:32768:8:1$vpafsxiJzgC38YFS$41cc27b127d488b996bcf4c9d41c9aec11eadc5e4341a36c238b5e34890ee600ee3b1d401952a3f5d552bafc916b2ebc8db0a06fe43a244e27bff95b87bc18ac','2025-05-08 00:54:03',NULL),
(18,'dr_sabri@hotmail.com','sabri','scrypt:32768:8:1$2glSsDU6yjqZ42qb$f49b4be41eb940b7a71d6eada6dff947b2433ee64d6f5d261391bb10dde480b89b433d3b447a0d23f1450353e07369d4199cefc3418b3c337c1edcc23e092591','2025-05-08 07:02:50',0),
(19,'someone@gmail.com','someone','scrypt:32768:8:1$kesBOCpb9QdD9gPT$387c914913160ea76421b35dea5c9ab8109f01633c99f133e644cf363dd1cfc133e8f834e15229dbaa8fb39600b482034f9d38c6b5d1d360d2290388e69a163f','2025-05-13 22:07:57',0),
(20,'hana2300517@miuegypt.edu.eg','hanakhalid','scrypt:32768:8:1$0RlWgwjuPKWxKTVd$722ff676519ae5d9930de4478d91b492a5299560cc60f9c9a539bed5bab82654b3679bc5909096982593c38f0c027c0208476970387b31494ec8aea43b33ee0b','2025-05-17 21:36:09',0);
/*!40000 ALTER TABLE `customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `orderID` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `size_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` float NOT NULL,
  `status` enum('pending','shipped','delivered','canceled') NOT NULL,
  `payment_id` varchar(1000) NOT NULL,
  `ordered_at` datetime DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` text DEFAULT NULL,
  PRIMARY KEY (`orderID`),
  KEY `customer_id` (`customer_id`),
  KEY `product_id` (`product_id`),
  KEY `size_id` (`size_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`pID`),
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`size_id`) REFERENCES `product_sizes` (`sizeID`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES
(7,11,25,28,2,1200,'shipped','cash_on_delivery','2025-05-08 05:56:19','yasseen','yasseen@lord.com','cairo maad, masr helwan elziraa'),
(8,11,26,30,1,950,'pending','cash_on_delivery','2025-05-08 05:56:19','yasseen','yasseen@lord.com','cairo maad, masr helwan elziraa'),
(9,11,25,28,1,1200,'pending','cash_on_delivery','2025-05-08 06:02:14','first order','first@gmail.com','first'),
(10,11,28,40,1,650,'pending','cash_on_delivery','2025-05-08 10:16:50','Jana mahmoud','any@gmaiil.com','nasr city'),
(11,19,26,32,1,950,'pending','cash_on_delivery','2025-05-13 22:10:22','someone','someone@gmail.com','somewhere'),
(12,11,25,28,1,1200,'pending','cash_on_delivery','2025-05-13 22:15:39','someone','someone@gmail.com','somewhere'),
(13,20,26,31,4,950,'canceled','cash_on_delivery','2025-05-17 21:39:23','hana','hana2300517@miuegypt.edu.eg','midtown compound 1'),
(14,11,25,28,2,1200,'shipped','cash_on_delivery','2025-05-21 15:16:04','yasseen','yasseenbass@gmail.com','cairo maad');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_photos`
--

DROP TABLE IF EXISTS `product_photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_photos` (
  `photoID` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `image_url` varchar(1024) NOT NULL,
  `photo_order` int(11) DEFAULT NULL,
  PRIMARY KEY (`photoID`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `product_photos_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`pID`)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_photos`
--

LOCK TABLES `product_photos` WRITE;
/*!40000 ALTER TABLE `product_photos` DISABLE KEYS */;
INSERT INTO `product_photos` VALUES
(33,25,'photo_1_2025-05-08_03-57-48.jpg',0),
(34,25,'photo_2_2025-05-08_03-57-48.jpg',1),
(35,25,'photo_2025-05-08_04-00-18.jpg',2),
(36,26,'linen_pants.jpg',0),
(37,26,'linen_pants2.jpg',1),
(38,26,'size_chart.jpg',2),
(39,27,'sweatpants.jpg',0),
(40,27,'sweatpants1.jpg',1),
(41,27,'size_chart.jpg',2),
(42,28,'mesh_top.jpg',0),
(43,28,'mesh_top1.jpg',1),
(44,28,'size_chart.jpg',2),
(45,30,'basic_27_1.jpg',0),
(46,30,'basic_27.jpg',1),
(47,30,'size_chart.jpg',2),
(48,31,'basic_hoodie.jpg',0),
(49,31,'basic_hoodie1.jpg',1),
(50,31,'size_chart.jpg',2),
(51,32,'denim.jpg',0),
(52,32,'denim1.jpg',1),
(53,32,'size_chart.jpg',2),
(54,33,'zip.jpg',0),
(55,33,'zip1.jpg',1),
(56,33,'size_chart.jpg',2);
/*!40000 ALTER TABLE `product_photos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_sizes`
--

DROP TABLE IF EXISTS `product_sizes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_sizes` (
  `sizeID` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `size_label` varchar(50) NOT NULL,
  `quantity` int(11) NOT NULL,
  PRIMARY KEY (`sizeID`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `product_sizes_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`pID`)
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_sizes`
--

LOCK TABLES `product_sizes` WRITE;
/*!40000 ALTER TABLE `product_sizes` DISABLE KEYS */;
INSERT INTO `product_sizes` VALUES
(27,25,'s',20),
(28,25,'M',22),
(29,26,'XS',10),
(30,26,'S',5),
(31,26,'M',15),
(32,26,'L',10),
(33,26,'XL',5),
(34,27,'XS',2),
(35,27,'S',5),
(36,27,'M',10),
(37,27,'L',2),
(38,27,'XL',1),
(39,28,'XS',5),
(40,28,'S',11),
(41,28,'M',9),
(42,28,'XL',2),
(43,30,'M',10),
(44,30,'L',7),
(45,31,'M',1),
(46,31,'XS',7),
(47,31,'L',2),
(48,32,'S',2),
(49,33,'M',2);
/*!40000 ALTER TABLE `product_sizes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `pID` int(11) NOT NULL AUTO_INCREMENT,
  `productName` varchar(100) NOT NULL,
  `productPrice` float NOT NULL,
  `description` text NOT NULL,
  `category_id` int(11) NOT NULL,
  `date_added` datetime DEFAULT NULL,
  `is_featured` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`pID`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`catID`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES
(25,'Knitted Jacket',1200,'Stay cozy and stylish with our premium puffer jacket. Its oversized fit and luxurious feel offer unparalleled warmth and comfort. Whether you’re braving the cold or simply adding a touch of urban chic to your outfit.',7,'2025-05-08 04:38:47',0),
(26,'linen pants',950,'Feel effortless style and year-round comfort. Imagine the luxurious feel of breathable linen in these versatile, plain design pants. The timeless regular cut and crisp straight cuffs ensure a polished look, whether you\'re keeping it casual or dressing up. These unisex linen pants are the key to understated elegance and all-day ease.',9,'2025-05-08 04:50:25',1),
(27,'Straight-fit Sweatpants',1200,'Indulge in pure comfort with our oversized cotton sweatpants. Crafted from the softest, most luxurious cotton, these pants are designed to feel like a hug. The relaxed fit and ribbed cuffs offer a stylish.',9,'2025-05-08 04:55:19',0),
(28,'off-shoulder top',650,'A stylish and versatile mesh top that combines fashion-forward design with comfortable breathability. Perfect for layering or wearing solo, this top features a semi-sheer mesh fabric that adds a bold, edgy touch to any outfit.',8,'2025-05-08 05:01:29',1),
(30,'basic 27 hoodie',950,'Enhance your everyday style with our oversized printed cotton hoodies. Crafted from superior, soft cotton, these hoodies offer exceptional comfort and warmth. our hoodies will keep you cozy and stylish.',6,'2025-05-08 05:24:04',0),
(31,'VEGA hoodie',790,'Indulge in the sensation of our oversized cotton hoodie – where unparalleled comfort meets effortlessly cool style. Imagine sinking into the plush, cloud-like softness of premium, breathable cotton. This isn\'t just a hoodie; it\'s your new essential, seamlessly transitioning from cozy nights in to on-trend streetwear looks. The subtly placed minimalist logo adds an urban edge.',6,'2025-05-08 05:33:32',0),
(32,'Denim Jacket',1900,'Be stylish with our oversized washed denim jacket. Its relaxed fit and washed finish offer effortless chic, perfect for any wardrobe. Indulge in ultimate comfort and premium quality with this versatile jacket.',7,'2025-05-08 05:36:59',0),
(33,'Reborn Quarter-Zip',900,'Command attention and embrace unparalleled comfort with this season\'s must-have oversized sweatshirt. Featuring a striking, exclusive printed design that ignites your personal style, and a customizable quarter-zip for perfect temperature control, this unisex piece effortlessly transitions from cozy nights in to bold daytime adventures.',8,'2025-05-08 05:43:43',0);
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wishlist`
--

DROP TABLE IF EXISTS `wishlist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `wishlist` (
  `wishID` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `added_at` datetime DEFAULT NULL,
  PRIMARY KEY (`wishID`),
  KEY `customer_id` (`customer_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `wishlist_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  CONSTRAINT `wishlist_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`pID`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wishlist`
--

LOCK TABLES `wishlist` WRITE;
/*!40000 ALTER TABLE `wishlist` DISABLE KEYS */;
INSERT INTO `wishlist` VALUES
(13,11,25,'2025-05-08 05:29:28'),
(17,18,26,'2025-05-08 07:03:04'),
(18,18,27,'2025-05-08 07:03:12');
/*!40000 ALTER TABLE `wishlist` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-06-13  1:20:41

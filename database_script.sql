DROP TABLE appfigures_products;

CREATE TABLE appfigures_products (id int NOT NULL AUTO_INCREMENT, name varchar(255), icon_path varchar(255), sku varchar(255), package_name varchar(255), store varchar(50), release_date datetime, last_update datetime, last_version varchar(5), app_type varchar(50), downloads bigint DEFAULT '0', updates bigint DEFAULT '0', revenue float, active bit, id_trademark int, apikey_flurry varchar(50), apikey_flurry2 varchar(50), observation varchar(500), product_id bigint, PRIMARY KEY (id), CONSTRAINT appfigures_products_ix1 UNIQUE (product_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE appfigures_sales;

CREATE TABLE appfigures_sales (product_id bigint, downloads bigint, updates bigint, revenue float, collected_date datetime) ENGINE=InnoDB DEFAULT CHARSET=utf8;

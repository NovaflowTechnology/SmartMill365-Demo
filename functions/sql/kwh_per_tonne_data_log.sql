CREATE TABLE IF NOT EXISTS kWh_per_tonne_data_log (
  id               BIGINT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `date`           DATE          NOT NULL,
  machine_id       VARCHAR(255)  NULL,
  product_type     VARCHAR(255)  NULL,
  factory_id       VARCHAR(50)   NULL,
  plant_id         VARCHAR(50)   NULL,
  zone_id          VARCHAR(50)   NULL,
  kWh_consumed     DECIMAL(10,2) NOT NULL,
  tonnes_produced  DECIMAL(10,2) NOT NULL,
  variance         DECIMAL(10,2) NOT NULL,
  cost             DECIMAL(10,2) NOT NULL,
  status           ENUM('On target', 'Critical') NOT NULL,
  created_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_by       VARCHAR(50)   NULL
);

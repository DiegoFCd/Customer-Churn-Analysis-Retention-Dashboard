use `po-db`;

SELECT * FROM `user_telcocustomer_churn`;

SELECT 
  customerID,
  gender,
  SeniorCitizen,
  tenure,
  MonthlyCharges,
  TotalCharges,
  Contract,
  CASE 
    WHEN Churn = 'Yes' THEN 1
    ELSE 0
  END as churn
FROM `user_telcocustomer_churn`;

-- Porcentaje de perdida o cambio de clientes durante el tiempo analizado
-- análisis de churn
SELECT
 AVG(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churn_rate
FROM `user_telcocustomer_churn`; 

-- churm o porcentaje de perdida o cambio de cleintes por el atributo `Contract`
-- segmentación
SELECT 
 Contract,
 AVG(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS contract_churn_rate
FROM `user_telcocustomer_churn`
GROUP BY Contract;

-- Churn vs Antiguedad (ternure = tiempo como cliente)
-- métricas de negocio
SELECT 
  CASE 
    WHEN tenure < 12 THEN 'new'
    WHEN tenure < 24 THEN 'mid'
    ELSE 'long'	
  END as segment,
  AVG(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) as churn_rate
FROM `user_telcocustomer_churn`
GROUP BY segment;

-- IMPORTANTE (cambio de mentalidad)

-- Antes pensabas: 👉 “necesito varias tablas”
-- Ahora: 👉 “puedo transformar datos según necesidad”
-- 💥 Eso es mentalidad Analytics Engineer

-- Lo que acabás de entender (clave)
-- Antes: “Tengo datos → hago queries”
-- Ahora: “Tengo un problema de negocio → modelo datos → saco decisiones”
-- 👉 Ese cambio te sube de nivel automáticamente.


CREATE TABLE user_metrics AS
SELECT 
  customerID,
  gender,
  SeniorCitizen,
  tenure,
  MonthlyCharges,
  TotalCharges,
  Contract,
  CASE 
    WHEN Churn = 'Yes' THEN 1
    ELSE 0
  END as churn
FROM `user_telcocustomer_churn`;

-- Accedo a la tabla:
USE user_metrics;

SELECT * FROM `user_telcocustomer_churn`;


-- Unificamos % de Chur con el conteo de clientes y tipo de contrato
SELECT 
  Contract,
  AVG(churn) as churn_rate,
  COUNT(*) as users
FROM user_metrics
GROUP BY Contract;    -- “Clientes con contrato mensual tienen mayor churn, lo que indica baja fidelización”

-- Chequeo si precio influye en abandono
SELECT
 CASE
   WHEN MonthlyCharges < 50 THEN 'LOW'
   WHEN MonthlyCharges < 80 THEN 'MID'
   ELSE 'HIGH'
END AS price_segment,
AVG(churn) AS churn_rate
FROM user_metrics
GROUP BY price_segment;

-- Cómo vender esto: Construí una capa analítica desde datos crudos, modelé métricas de churn 
-- y detecté que el tipo de contrato y la actividad temprana impactan directamente en la retención

-- inprovement: NTILE
SELECT
    customerID,
    MonthlyCharges,
    churn,
    NTILE(3) OVER (ORDER BY MonthlyCharges) AS price_segment
FROM user_metrics;

-- BALANCEO LOS GRUPOS	
SELECT
    CASE 
        WHEN price_segment = 1 THEN 'Low'
        WHEN price_segment = 2 THEN 'Mid'
        ELSE 'High'
    END AS segment,
    AVG(churn) AS churn_rate,
    COUNT(*) AS total_customers
FROM (
    SELECT *,
           NTILE(3) OVER (ORDER BY MonthlyCharges) AS price_segment
    FROM user_metrics
) t
GROUP BY segment;
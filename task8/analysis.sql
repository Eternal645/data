-- 1. Анализ наличия ресурсов
-- 1.1. Закупки
select * from bm_StorageOperations_Table;
select * from bm_StorageOperations;

-- 1.2. Продажи
select * from vw_SalesTicketInfo;

-- 1.3. Поставщики
select * from vendors;

-- 1.4. Персонал
select * from bm_WorkHours;
select * from personnel;

-- 1.5. Остатки
select * from bm_Journal_Details;
select * from bm_StorageOperations_Table;

-- 2. Список основных и связанных таблиц
-- 2.1. Закупки
select * from bm_JournalBarnetDocs; -- документы операций
select * from product; -- справочник товаров
select * from bm_JournalTypeDocuments; -- типы документов
select * from storages; -- склады
select * from bm_StorageOperations; -- складские операции
select * from bm_StorageOperations_Table; -- складские операции
select * from vendors; -- поставщики
select * from bm_Contracts; -- договоры
select * from bm_StorageOperationsType; -- типы складских операций

-- 2.2. Продажи
select * from pricelist; -- информация о ценах
select * from product; -- справочник товаров
select * from vw_SalesTicketInfo; -- факты продаж

-- 2.3. Поставщики
select * from bm_StorageOperations; -- складские операции
select * from vendors; -- справочник поставщиков
select * from bm_JournalBarnetDocs; -- документы операций

-- 2.4. Персонал
select * from bm_BonusHistory; -- история бонусов
select * from personnel; -- информация о сотрудниках
select * from bm_WorkHours; -- рабочее время сотрудников

-- 2.5. Остатки
select * from bm_JournalBarnetDocs; -- документы операций
select * from bm_StorageOperations_Table; -- складские операции
select * from bm_Journal_Details; -- детали журнала

-- 4. Запросы которые подтверждают корректность выводов
-- 4.1. Закупки - соединяем операции с документами
select * from bm_StorageOperations 
join bm_JournalBarnetDocs on bm_StorageOperations.DocumentID = bm_JournalBarnetDocs.ID;

-- соединяем операции и склады
select * from bm_StorageOperations
join storages on bm_StorageOperations.StorageID = storages.id;

-- соединяем документы и их типы
select * from bm_JournalBarnetDocs
join bm_JournalTypeDocuments on bm_JournalBarnetDocs.DocumentTypeID = bm_JournalTypeDocuments.ID;

-- соединяем операции и договоры
select * from bm_StorageOperations
join bm_Contracts on bm_StorageOperations.ContractID = bm_Contracts.ID;

-- соединяем операции и их типы
select * from bm_StorageOperations
join bm_StorageOperationsType on bm_StorageOperations.OperationID = bm_StorageOperationsType.ID;

-- 4.2. Продажи - соединяем цены с товарами
select * from pricelist 
join product on pricelist.productid = product.id;

-- 4.3. Поставщики - соединяем операции с поставщиками
select * from bm_StorageOperations 
join vendors on bm_StorageOperations.VendorID = vendors.id;

-- 4.4. Персонал - соединяем сотрудников с историей бонусов
select * from bm_BonusHistory 
join personnel on bm_BonusHistory.PersonID = personnel.personid;

-- 4.5. Остатки - соединяем складские операции с документами
select * from bm_StorageOperations_Table 
join bm_JournalBarnetDocs on bm_StorageOperations_Table.DocumentID = bm_JournalBarnetDocs.ID;

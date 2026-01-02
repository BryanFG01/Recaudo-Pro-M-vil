-- Add payment_method and transaction_reference columns to collections table

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'collections' AND column_name = 'payment_method') THEN
        ALTER TABLE collections ADD COLUMN payment_method TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'collections' AND column_name = 'transaction_reference') THEN
        ALTER TABLE collections ADD COLUMN transaction_reference TEXT;
    END IF;
END $$;

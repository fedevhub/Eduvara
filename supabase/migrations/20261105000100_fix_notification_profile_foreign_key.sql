DO $$
DECLARE
  user_id_attnum smallint;
  foreign_key record;
BEGIN
  IF to_regclass('public.notifications') IS NULL
     OR to_regclass('public.profiles') IS NULL THEN
    RAISE EXCEPTION
      'public.notifications and public.profiles must exist before fixing notification ownership.';
  END IF;

  SELECT attribute.attnum
  INTO user_id_attnum
  FROM pg_attribute AS attribute
  WHERE attribute.attrelid = 'public.notifications'::regclass
    AND attribute.attname = 'user_id'
    AND NOT attribute.attisdropped;

  IF user_id_attnum IS NULL THEN
    RAISE EXCEPTION 'public.notifications must contain a user_id column.';
  END IF;

  FOR foreign_key IN
    SELECT constraint_row.conname, constraint_row.confrelid
    FROM pg_constraint AS constraint_row
    WHERE constraint_row.conrelid = 'public.notifications'::regclass
      AND constraint_row.contype = 'f'
      AND constraint_row.conkey = ARRAY[user_id_attnum]::smallint[]
  LOOP
    IF foreign_key.confrelid <> 'public.profiles'::regclass THEN
      EXECUTE format(
        'ALTER TABLE public.notifications DROP CONSTRAINT %I',
        foreign_key.conname
      );
    END IF;
  END LOOP;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint AS constraint_row
    WHERE constraint_row.conrelid = 'public.notifications'::regclass
      AND constraint_row.confrelid = 'public.profiles'::regclass
      AND constraint_row.contype = 'f'
      AND constraint_row.conkey = ARRAY[user_id_attnum]::smallint[]
  ) THEN
    ALTER TABLE public.notifications
      ADD CONSTRAINT notifications_user_id_profiles_fkey
      FOREIGN KEY (user_id)
      REFERENCES public.profiles(id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END;
$$;

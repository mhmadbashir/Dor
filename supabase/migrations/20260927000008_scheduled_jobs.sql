-- Scheduled jobs (pg_cron) and invoking the send-notifications Edge Function
-- (pg_net). The function URL and a shared secret are read from Vault:
--
--   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
--   select vault.create_secret('<random string>', 'notify_cron_secret');
--
-- and the same secret is set on the function: supabase secrets set NOTIFY_CRON_SECRET=...
-- Without these secrets the job is a no-op, so nothing breaks before setup.

create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

create or replace function public.invoke_send_notifications()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url    text;
  v_secret text;
begin
  if not exists (select 1 from public.notification_outbox where processed_at is null and attempts < 5) then
    return;
  end if;
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'project_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'notify_cron_secret';
  if v_url is null or v_secret is null then
    return;
  end if;
  perform net.http_post(
    url     := v_url || '/functions/v1/send-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_secret
    ),
    body    := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
end;
$$;

revoke execute on function public.invoke_send_notifications() from public, anon, authenticated;

-- Send queued pushes every minute.
select cron.schedule('send-notifications', '* * * * *', 'select public.invoke_send_notifications()');

-- Let reports age out of the 12-hour window.
select cron.schedule('refresh-neighborhood-status', '*/10 * * * *',
  'select public.refresh_active_neighborhood_statuses()');

-- Day-before reminders at 20:00 Amman time (17:00 UTC; Jordan has no DST).
select cron.schedule('enqueue-schedule-reminders', '0 17 * * *',
  'select public.enqueue_schedule_reminders()');

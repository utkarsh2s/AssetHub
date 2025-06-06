create table public.n8n_chat_histories (
  id serial not null,
  session_id character varying(255) not null,
  message jsonb not null,
  constraint n8n_chat_histories_pkey primary key (id)
) TABLESPACE pg_default;
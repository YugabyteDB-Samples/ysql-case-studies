do $body$
begin
  begin
    drop owned by clstr$mgr cascade;
  exception when undefined_object then null; end;
  begin
    drop owned by clstr$developer cascade;
  exception when undefined_object then null; end;
end;
$body$;


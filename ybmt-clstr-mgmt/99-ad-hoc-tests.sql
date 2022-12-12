AD HOC TESTS
------------
:cr_u0
:cm
\t on

select mgr.tenant_role_name('Dog');
select mgr.tenant_role_name('dog house');
select mgr.tenant_role_name('redaktør');
select mgr.tenant_role_name('中文');
select mgr.tenant_role_name('dog$house');
select mgr.tenant_role_name('7dog');
select mgr.tenant_role_name('_dog');

select mgr.tenant_role_name('dog_house42');

select mgr.is_good_tenant_role_name('$doghouse')::text;
select mgr.is_good_tenant_role_name('doghouse$')::text;
select mgr.is_good_tenant_role_name('dog$$house')::text;
select mgr.is_good_tenant_role_name('dog$house$what')::text;
select mgr.is_good_tenant_role_name('dog$ho^se')::text;
select mgr.is_good_tenant_role_name('1og$house')::text;

select mgr.is_good_tenant_role_name('dog$house')::text;

\t off

select name from mgr.proper_ybmt_roles order by 1;
create role bad_name;
grant connect on database d0 to bad_name;
select name from mgr.improper_ybmt_roles order by 1;

create role bad$bad$name;
grant connect on database d0 to bad$bad$name;
select name from mgr.improper_ybmt_roles order by 1;

create role cannot_connect_anywhere;
select name from mgr.improper_ybmt_roles order by 1;

:cm0
call cr_role('u0');

:cm
grant connect on database d2 to d0$u0;
select name from mgr.improper_ybmt_roles order by 1;

call mgr.drop_all_improper_ybmt_roles();
select name from mgr.improper_ybmt_roles order by 1;

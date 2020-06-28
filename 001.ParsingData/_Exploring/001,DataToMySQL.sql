-- ------------------------------------------------------------------------------
-- Cria tabela de stage
-- ------------------------------------------------------------------------------

drop table if exists sta_logradouros;

create table sta_logradouros
select *
from sirgas_shp_logradouronbl ssl2;

alter table sta_logradouros
add column `id` int auto_increment primary key;

-- ------------------------------------------------------------------------------
-- Exclui os registos de 'passagens'
-- ------------------------------------------------------------------------------

update sta_logradouros
set	lg_ini_par = null, lg_fim_par = null
where lg_ini_par = 0 and lg_fim_par = 0;

update sta_logradouros
set	lg_ini_imp = null, lg_fim_imp = null
where lg_ini_imp = 0 and lg_fim_imp = 0;

-- delete from sta_logradouros
-- where
-- 	lg_ini_par is null and lg_fim_par is null
-- and lg_ini_imp is null and lg_fim_imp is null;


-- ------------------------------------------------------------------------------
-- Valida que todos ini e fim são coerentes
-- ------------------------------------------------------------------------------

select *
from sta_logradouros 
where
       (lg_ini_par is null     and lg_fim_par is not null)
	or (lg_ini_par is not null and lg_fim_par is null)
	or (lg_ini_imp is null     and lg_fim_imp is not null)
	or (lg_ini_imp is not null and lg_fim_imp is null);

-- ------------------------------------------------------------------------------
-- Ajusta os segmentos
-- ------------------------------------------------------------------------------

alter table sta_logradouros
add	lg_ini int;

alter table sta_logradouros
add	lg_fim int;

update
	sta_logradouros l
		inner join(
			select
				lg_id, lg_seg_id,
				(lg_ini_par div 2) * 2 + 1 as lg_ini,
				 lg_fim_par                as lg_fim
			from sta_logradouros
			where lg_ini_imp is null
			-- --------
			union all
			-- --------
			select
				lg_id, lg_seg_id,
				 lg_ini_imp            as lg_ini,
				(lg_fim_imp div 2) * 2 as lg_fim
			from sta_logradouros
			where lg_ini_par is null
			-- --------
			union all
			-- --------
			select
				lg_id, lg_seg_id,
				lg_ini_imp as lg_ini,
				lg_fim_par as lg_fim
			from sta_logradouros
			where
				lg_ini_par is not null
			and lg_ini_imp is not null
		) l_ini_fim
		on(
				l_ini_fim.lg_id     = l.lg_id
			and l_ini_fim.lg_seg_id = l.lg_seg_id	
		)
set
	l.lg_ini = l_ini_fim.lg_ini,
	l.lg_fim = l_ini_fim.lg_fim
where 1 = 1;

update sta_logradouros
set lg_fim = lg_ini
where lg_fim = lg_ini - 1;

-- ------------------------------------------------------------------------------
-- Cria a tabela logradouros
-- ------------------------------------------------------------------------------

drop table if exists dat_logradouros;

create table dat_logradouros
select distinct lg_id, lg_codlog, lg_tipo, lg_titulo, lg_prep, lg_nome
from sta_logradouros;

alter table dat_logradouros
add constraint pk_dat_logradouros
primary key(lg_id);








-- ------------------------------------------------------------------------------
-- Valida que os nós têm um correspondente posterior com base em lg_ordem
-- ------------------------------------------------------------------------------

with ssl_max as(
	select ssl_max.lg_id, max(ssl_max.lg_ordem) as max_lg_ordem
	from sta_logradourosssl_max
	group by ssl_max.lg_id
)
select ssl2.*
from
	sta_logradourosssl2 
		inner join ssl_max
		on ssl_max.lg_id = ssl2.lg_id
where
	not exists(
		select *
		from sta_logradourosssl3
		where
			ssl3.lg_id    = ssl2.lg_id
		and ssl3.lg_ordem = ssl2.lg_ordem  + 1
	)
and ssl2.lg_ordem <> ssl_max.max_lg_ordem















-- Cria a coluna 'mao_dupla'
	
alter table sta_logradouros
drop column mao_dupla;

alter table sirgas_shp_logradouronbl
add mao_dupla bit default 1;

update sta_logradouros
set mao_dupla = 0
where
	lg_ini_imp is not null
and lg_fim_imp is not null;
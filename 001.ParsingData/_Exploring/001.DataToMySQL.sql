-- ------------------------------------------------------------------------------
-- Cria tabela de stage
-- ------------------------------------------------------------------------------

drop table if exists sta_logradouros;

create table sta_logradouros
select *
from sirgas_shp_logradouronbl;

alter table sta_logradouros
add column `id` int auto_increment primary key;

create index ix_sta_logradouros_seg
on sta_logradouros(lg_seg_id);

-- ------------------------------------------------------------------------------
-- Exclui os registos de 'passagens'
-- ------------------------------------------------------------------------------

update sta_logradouros
set	lg_ini_par = null, lg_fim_par = null
where lg_ini_par = 0 and lg_fim_par = 0;

update sta_logradouros
set	lg_ini_imp = null, lg_fim_imp = null
where lg_ini_imp = 0 and lg_fim_imp = 0;


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
set
	lg_ini = (@temp:=lg_ini),
	lg_ini = lg_fim,
	lg_fim = @temp
where lg_fim = lg_ini - 1;

update sta_logradouros
set lg_fim = lg_ini + 1
where lg_fim = lg_ini - 1;


-- ------------------------------------------------------------------------------
-- Cria a tabela dat_logradouros
-- ------------------------------------------------------------------------------

drop table if exists dat_logradouros_segmentos;
drop table if exists dat_logradouros;

create table dat_logradouros
select distinct lg_id, lg_codlog, lg_tipo, lg_titulo, lg_prep, lg_nome
from sta_logradouros;

alter table dat_logradouros
add constraint pk_dat_logradouros
primary key(lg_id);

-- -----------------------------------------------------------------------------
-- Cria a tabela dat_logradouros_segmentos
-- -----------------------------------------------------------------------------

create table dat_logradouros_segmentos(
	`id` bigint auto_increment primary key,
	lg_id  bigint not null,
	lg_ini int,
	lg_fim int,
	lg_seg_id bigint not null,
	--
	constraint fk_dat_log_seg
	foreign key(lg_id)
	references dat_logradouros(lg_id)
);

-- -----------------------------------------------------------------------------
-- Dump em dat_logradouros os segmentos sem dt
-- -----------------------------------------------------------------------------

insert into dat_logradouros_segmentos(lg_id, lg_ini, lg_fim, lg_seg_id)
select
	distinct
		lg_id, lg_ini, lg_fim, lg_seg_id
from sta_logradouros sl2 
where
	lg_ini is null
and lg_fim is null;

delete from sta_logradouros
where lg_ini is null and lg_fim is null;

-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

drop table if exists `_sta_logradouros`;

create table `_sta_logradouros`
with lg as(	select lg_id, lg_ini as lg_number
	from sta_logradouros sl
	-- ---------
	union all
	-- ---------
	select lg_id, lg_fim as lg_number
	from sta_logradouros sl 
)
select distinct
	lg.lg_id, lg.lg_number as lg_ini, lg_next.lg_number as lg_fim
from
	lg
		inner join lg lg_next
		on lg_next.lg_id = lg.lg_id
where
	lg_next.lg_number =(
		select min(lg_min_next.lg_number)
		from lg lg_min_next
		where
			lg_min_next.lg_id     = lg.lg_id
		and lg_min_next.lg_number > lg.lg_number
	);

update `_sta_logradouros`
set lg_ini = lg_ini + 1
where lg_ini % 2 = 0;

update `_sta_logradouros`
set lg_fim = lg_fim - 1
where lg_fim % 2 = 1;

delete from `_sta_logradouros` 
where
	lg_ini = lg_fim
 or lg_ini = lg_fim + 1;


create index tmp_ix_sta_logradouros
on _sta_logradouros(lg_id, lg_ini, lg_fim);

-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

insert into dat_logradouros_segmentos(lg_id, lg_ini, lg_fim, lg_seg_id)
select sl.lg_id, _sl.lg_ini, _sl.lg_fim, sl.lg_seg_id
from
	sta_logradouros sl
		inner join `_sta_logradouros` _sl
		on(
			    _sl.lg_id = sl.lg_id
			and _sl.lg_ini <= sl.lg_fim
			and _sl.lg_fim >= sl.lg_ini
		);
	
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

drop table if exists dat_logradouros_ini_fim;

create table dat_logradouros_ini_fim(
	`id` int not null auto_increment primary key,
	lg_id  bigint not null,
	lg_ini int not null,
	lg_fim int not null,
	mao_dupla bit default 0
)
select sl.lg_id, sl.lg_ini, sl.lg_fim, cast(null as integer) as lg_ordem
from `_sta_logradouros` sl;

-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

drop temporary table if exists _l_ord;

create temporary table _l_ord(
	id int primary key,
	ordem int
)
select id, lg_id, rank() over(partition by lg_id order by lg_ini, lg_fim) as ordem
from dat_logradouros_ini_fim dl;

update
	dat_logradouros_ini_fim l
		inner join _l_ord
		on _l_ord.id = l.id
set l.lg_ordem = _l_ord.ordem
where 1 = 1;


-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

create index ak_dat_dlif
on dat_logradouros_ini_fim(lg_id, lg_ordem, id)

select lg_id, lg_ini
from dat_logradouros_ini_fim dlif 
group by lg_id, lg_ini
having count(*) > 1

select *
from
	dat_logradouros_ini_fim dlif 
		inner join dat_logradouros_ini_fim dlif_oth
		on(
                dlif_oth.lg_id = dlif.lg_id
			and dlif_oth.lg_ordem = dlif.lg_ordem + 1
		)
where dlif.lg_fim + 1 <> dlif_oth.lg_ini


-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

select *
from
	dat_logradouros dl
		inner join dat_logradouros_ini_fim dlif
		on dlif.lg_id = dl.lg_id 
order by dlif.lg_ordem;


-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

update dat_logradouros_ini_fim lif
set mao_dupla = 1
where
	exists(
		select *
		from
			dat_logradouros_segmentos ls
				inner join sta_logradouros lg
				on lg.lg_seg_id = ls.lg_seg_id
		where
			ls.lg_id  = lif.lg_id
		and ls.lg_ini = lif.lg_ini
		and ls.lg_fim = lif.lg_fim
		--
		and lg.lg_ini_par is not null
	)	
and exists(
		select *
		from
			dat_logradouros_segmentos ls
				inner join sta_logradouros lg
				on lg.lg_seg_id = ls.lg_seg_id
		where
			ls.lg_id  = lif.lg_id
		and ls.lg_ini = lif.lg_ini
		and ls.lg_fim = lif.lg_fim
		--
		and lg.lg_ini_imp is not null
	)


-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------

select *
from
	dat_logradouros dl
		inner join dat_logradouros_ini_fim dlif
		on dlif.lg_id = dl.lg_id 
where lg_tipo = 'AV'
and lg_nome = 'JOAO'
order by dlif.lg_ordem;
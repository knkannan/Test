create or replace procedure        CONSISTIR_ITEM_REQUISICAO(

		cd_material_p			number,

		nr_requisicao_p			number,

		VarConsisteMaterialCCusto_p		varchar2,

		VarObrigaMaterialpadr_p		varchar2,

		VarConsisteMaterialLocal_p		varchar2,

		VarConsisteEstoqueDisp_p		varchar2,

		VarPermiteEstoqueMax_p		varchar2,

		ie_consiste_consignado_p		varchar2,

		nm_usuario_p			varchar2,

		ie_deleta_consistencia_p		varchar2,

		cd_cgc_fornecedor_p		out	varchar2,

		ds_erro				out	varchar2) is





ie_req_mat_estoque_w			varchar2(1);

ie_material_estoque_w			varchar2(1);

ie_situacao_w				varchar2(1);

ie_situacao_est_w				varchar2(1);

ie_padronizado_w				varchar2(1);

ie_consignado_material_w			varchar2(1);

ie_consignado_w				number(20);

ie_permite_w				varchar2(1);

ie_local_valido_baixa_w			varchar2(1);

ie_local_valido_destino_w			varchar2(1);

cd_operacao_estoque_w			number(20);

cd_centro_custo_w				number(20);

cd_estabelecimento_w			number(10);

ie_local_valido_w				varchar2(1);

cd_local_estoque_destino_w			number(20);

Valida_material_w				varchar2(1);

cd_local_estoque_w			number(20);

ds_erro_w				varchar2(20000);

ds_material_w				varchar2(255);

cd_kit_material_w				number(05,0);

ie_tipo_requisicao_w			varchar2(3);

cd_material_estoque_w			number(6);

ie_requisicao_w				varchar2(1);

dt_solicitacao_requisicao_w			date;

cd_pessoa_requisitante_w			varchar2(10);

qt_material_requisitada_w			number(15,4);

qt_regra_w				number(13,4);

qt_estoque_w				number(15,4);

qt_estoque_maximo_w			number(15,4);

ie_consiste_sem_movto_w			varchar2(1);

ie_possui_movto_w				varchar2(1);

ie_busca_fornec_consig_w			varchar2(255);

cd_material_substituto_w		sup_lista_subs_material.cd_material%type;

ds_material_substituto_w		varchar(255);

ds_consistencia_substituto_w		varchar(255);

ie_geracao_w				requisicao_material.ie_geracao%type;



begin

ds_erro := '';



select	distinct

	b.cd_operacao_estoque,

	b.cd_centro_custo,

	b.cd_estabelecimento,

	b.cd_local_estoque_destino,

	b.cd_local_estoque,

	c.ie_consignado,

	ie_tipo_requisicao,

	b.dt_solicitacao_requisicao,

	b.cd_pessoa_requisitante,

	b.ie_geracao

into	cd_operacao_estoque_w,

	cd_centro_custo_w,

	cd_estabelecimento_w,

	cd_local_estoque_destino_w,

	cd_local_estoque_w,

	ie_consignado_w,

	ie_tipo_requisicao_w,

	dt_solicitacao_requisicao_w,

	cd_pessoa_requisitante_w,

	ie_geracao_w

from	requisicao_material b,

	operacao_estoque C

where	c.cd_operacao_estoque = b.cd_operacao_estoque

and	b.nr_requisicao = nr_requisicao_p;



ie_consiste_sem_movto_w		:= obter_valor_param_usuario(919, 75, Obter_perfil_ativo, nm_usuario_p, cd_estabelecimento_w);

ie_busca_fornec_consig_w	:= obter_valor_param_usuario(919, 97, Obter_perfil_ativo, nm_usuario_p, cd_estabelecimento_w);



begin



if	(ie_deleta_consistencia_p = 'S') then

	delete from requisicao_mat_consist

	where nr_requisicao = nr_requisicao_p;

end if;



select	nvl(sum(qt_material_requisitada), 0),

	nvl(sum(qt_estoque), 0)

into	qt_material_requisitada_w,

	qt_estoque_w

from	item_requisicao_material

where	nr_requisicao	= nr_requisicao_p

and	cd_material	= cd_material_p;

exception

	when others then

		qt_material_requisitada_w	:= 0;

end;



select	a.ie_situacao,

	nvl(a.ie_consignado,'X'),

	a.ds_material,

	a.cd_material_estoque

into	ie_situacao_w,

	ie_consignado_material_w,

	ds_material_w,

	cd_material_estoque_w

from	material a

where	a.cd_material = cd_material_p;



begin

select	b.ie_padronizado,

	b.cd_kit_material,

	nvl(b.ie_requisicao,'S'),

	nvl(b.ie_material_estoque,'S')

into	ie_padronizado_w,

	cd_kit_material_w,

	ie_requisicao_w,

	ie_material_estoque_w

from	material_estab b

where	b.cd_estabelecimento = cd_estabelecimento_w

and	b.cd_material = cd_material_p;

exception

when others then

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1', 

		WHEB_MENSAGEM_PCK.get_texto(300028), 

		'C', WHEB_MENSAGEM_PCK.get_texto(300029), nm_usuario_p);

end;



select	ie_situacao

into	ie_situacao_est_w

from	material

where	cd_material = cd_material_estoque_w;



if	(ie_consiste_sem_movto_w = 'S') and

	(ie_tipo_requisicao_w in (3,9)) then



	select	obter_se_mat_possui_movto(cd_material_p, cd_estabelecimento_w, 0)

	into	ie_possui_movto_w

	from	dual;



	if	(ie_possui_movto_w = 'N') then

		gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(300030),

		'C',WHEB_MENSAGEM_PCK.get_texto(300031), nm_usuario_p);

	end if;

end if;



if	(ie_requisicao_w = 'N') then

	ds_erro := WHEB_MENSAGEM_PCK.get_texto(300032, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(300034),

		'C',WHEB_MENSAGEM_PCK.get_texto(300035), nm_usuario_p);

end if;



select	nvl(max(ie_req_mat_estoque),'S')

into	ie_req_mat_estoque_w

from	local_estoque

where	cd_local_estoque = cd_local_estoque_w;



if	(nvl(ie_geracao_w,'X') <> 'I') and

	(ie_req_mat_estoque_w = 'S') and

	(ie_material_estoque_w = 'N') and

	(cd_kit_material_w is null) then

	ds_erro := WHEB_MENSAGEM_PCK.get_texto(300042, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(300045) /*'Este material não é um material de estoque.'*/,

		'C',WHEB_MENSAGEM_PCK.get_texto(300049), nm_usuario_p);

end if;



if	(ie_consignado_material_w = 'X') then

	ds_erro := WHEB_MENSAGEM_PCK.get_texto(300050, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(280507),

		'C',WHEB_MENSAGEM_PCK.get_texto(280508), nm_usuario_p);

end if;



if	(ie_situacao_w = 'I') then

	ds_erro := WHEB_MENSAGEM_PCK.get_texto(300073, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(300077),

		'C',WHEB_MENSAGEM_PCK.get_texto(300078), nm_usuario_p);	

end if;



begin

select	cd_material

into	cd_material_substituto_w

from	(

select	a.cd_material

from	sup_lista_subs_material a,

	sup_regra_subs_material b

where	b.cd_material = cd_material_p

and	a.nr_seq_regra = b.nr_sequencia

order by nvl(ie_ordem,999))

where	rownum = 1;

exception

when others then

	cd_material_substituto_w	:=	null;

end;



if	(cd_material_substituto_w is not null) then

	select	ds_material

	into	ds_material_substituto_w

	from	material

	where	cd_material = cd_material_substituto_w;

	ds_consistencia_substituto_w := substr(obter_texto_tasy(287854,wheb_usuario_pck.get_nr_seq_idioma) || 

					cd_material_substituto_w || obter_texto_tasy(287859,wheb_usuario_pck.get_nr_seq_idioma) || ds_material_substituto_w, 1, 255);

end if;

	

if	(ie_situacao_est_w = 'I') then

	ds_erro := WHEB_MENSAGEM_PCK.get_texto(300080, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(300081),

		'C',WHEB_MENSAGEM_PCK.get_texto(300082, 'CD_MATERIAL_ESTOQUE=' || cd_material_estoque_w || ';DS_CONSISTENCIA_SUBSTITUTO=' || ds_consistencia_substituto_w), nm_usuario_p);

end if;



if	(ie_padronizado_w <> 'S') and 

	(VarObrigaMaterialpadr_p = 'S') then

	ds_erro := WHEB_MENSAGEM_PCK.get_texto(300083, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(300084),

		'C',WHEB_MENSAGEM_PCK.get_texto(342840), nm_usuario_p);	

end if;



if	(nvl(ie_consiste_consignado_p,'S') = 'S') and

	(((ie_consignado_w <> 0 ) and (ie_consignado_material_w = '0')) or 

	((ie_consignado_w = 0) and (ie_consignado_material_w = '1'))) then

	ds_erro := WHEB_MENSAGEM_PCK.get_texto(300087, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

	gravar_consistencia_requisicao(

		nr_requisicao_p, cd_material_p,'1',

		WHEB_MENSAGEM_PCK.get_texto(300085),

		'C',WHEB_MENSAGEM_PCK.get_texto(300089), nm_usuario_p);

end if;



if	(VarPermiteEstoqueMax_p = 'N') and

	(ie_tipo_requisicao_w in (2,21)) and

	(cd_local_estoque_destino_w > 0) then

	qt_estoque_maximo_w	:= nvl(obter_regra_padrao_local(cd_material_p, cd_local_estoque_destino_w, cd_estabelecimento_w, 'qt_max'),0);

		

	if	(qt_estoque_maximo_w > 0) and

		(qt_estoque_w > qt_estoque_maximo_w) then

		ds_erro := WHEB_MENSAGEM_PCK.get_texto(300090, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

		gravar_consistencia_requisicao(

			nr_requisicao_p, cd_material_p,'1',

			WHEB_MENSAGEM_PCK.get_texto(300091),

			'C', WHEB_MENSAGEM_PCK.get_texto(300092, 'DS_LOCAL_ESTOQUE=' || obter_desc_local_estoque(cd_local_estoque_destino_w) || 

													';QT_ESTOQUE=' || qt_estoque_w || 

													';QT_ESTOQUE_MAXIMO=' || qt_estoque_maximo_w), nm_usuario_p);

					

	end if;

end if;



if	(VarConsisteMaterialCCusto_p = 'S') and 

	(cd_centro_custo_w is not null) then

	begin

	valida_material_centro_custo(

		cd_material_p,

		cd_centro_custo_w,

		valida_material_w,

		cd_local_estoque_w,

		cd_operacao_estoque_w);

	if	(valida_material_w <> 'S') then

		ds_erro := WHEB_MENSAGEM_PCK.get_texto(300093, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

		gravar_consistencia_requisicao(

			nr_requisicao_p, cd_material_p,'1',

			WHEB_MENSAGEM_PCK.get_texto(300094),

			'C',WHEB_MENSAGEM_PCK.get_texto(342850), nm_usuario_p);

	end if;



	if	(qt_material_requisitada_w > 0) then

		valida_material_ccusto_qt(

			cd_material_p,

			cd_centro_custo_w,

			valida_material_w,

			cd_local_estoque_w,

			cd_operacao_estoque_w,

			qt_material_requisitada_w,

			qt_regra_w);

		if	(valida_material_w <> 'S') then

			ds_erro := WHEB_MENSAGEM_PCK.get_texto(300096, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

			gravar_consistencia_requisicao(

				nr_requisicao_p, cd_material_p,'1',

				WHEB_MENSAGEM_PCK.get_texto(300095),

				'C',WHEB_MENSAGEM_PCK.get_texto(300098), nm_usuario_p);

		end if;

	end if;

	end;

end if;



if	(VarConsisteMaterialLocal_p = 'S') then 

	begin

	obter_local_valido(cd_estabelecimento_w, cd_local_estoque_w, cd_material_p, 2 , ie_local_valido_w);

	if 	(ie_local_valido_w <> 'S') then

		ds_erro := WHEB_MENSAGEM_PCK.get_texto(300099, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

		gravar_consistencia_requisicao(

			nr_requisicao_p, cd_material_p,'1',

			WHEB_MENSAGEM_PCK.get_texto(300100),

			'C',WHEB_MENSAGEM_PCK.get_texto(300101) /*'Verifique na função Administração de estoque, pasta Padrões, subaba Liberação.'*/, nm_usuario_p);

		

		

	end if;

	if	(cd_local_estoque_destino_w is not null) then

		obter_local_valido(

			cd_estabelecimento_w, cd_local_estoque_destino_w ,cd_material_p,2,ie_local_valido_w);

		if 	(ie_local_valido_w <> 'S') then

			ds_erro := WHEB_MENSAGEM_PCK.get_texto(300102, 'CD_MATERIAL=' || cd_material_p || ';DS_MATERIAL=' || ds_material_w);

			gravar_consistencia_requisicao(

				nr_requisicao_p, cd_material_p,'1',

				WHEB_MENSAGEM_PCK.get_texto(300103),

				'C',WHEB_MENSAGEM_PCK.get_texto(300101) /*'Verifique na função Administração de estoque, pasta Padrões, subaba Liberação.'*/ , nm_usuario_p);					

		end if;

	end if;

	end;

end if;



if	(ie_busca_fornec_consig_w <> 'L') then

	begin

	cd_local_estoque_w := null;

	end;

end if;



if	(ie_consignado_w <> 0) and 

	(ie_consignado_material_w <> '0') then

	select	obter_fornecedor_regra_consig(cd_estabelecimento_w, cd_material_estoque_w, '1',cd_local_estoque_w)

	into	cd_cgc_fornecedor_p

	from	dual;

end if;



end consistir_item_requisicao;

 /* GOLDENGATE_DDL_REPLICATION */

--[[
	Sistema de Reset - Cliente OTClient
	Opcode: 220

	Interface visual para o sistema de reset de personagem.
	Permite visualizar informações, distribuir pontos e executar resets.
]]

local resetWindow = nil
local resetButton = nil
local RESET_OPCODE = 220

-- Cache de dados recebidos do servidor
local serverData = {}

function init()
	connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
	ProtocolGame.registerExtendedOpcode(RESET_OPCODE, parseOpcode)
	g_ui.importStyle('resetsystem')
	if g_game.isOnline() then onGameStart() end
end

function terminate()
	disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
	ProtocolGame.unregisterExtendedOpcode(RESET_OPCODE)
	destroyWindow()
	if resetButton then resetButton:destroy() resetButton = nil end
end

function destroyWindow()
	if resetWindow then
		resetWindow:destroy()
		resetWindow = nil
	end
end

function onGameStart()
	if resetButton then resetButton:destroy() resetButton = nil end
	if modules.game_mainpanel and modules.game_mainpanel.addSpecialToggleButton then
		resetButton = modules.game_mainpanel.addSpecialToggleButton(
			'resetSystemBtn', tr('Reset'), '/game_upgrade/images/upgrade_btn', toggle, false, 98
		)
	end
end

function onGameEnd()
	destroyWindow()
	if resetButton then resetButton:destroy() resetButton = nil end
	serverData = {}
end

function parseOpcode(protocol, opcode, buffer)
	local status, data = pcall(json.decode, buffer)
	if not status or not data then
		return
	end

	if data.action == "open" then
		serverData = data
		openWindow()

	elseif data.action == "resetResult" then
		if data.success then
			displayResult("Reset realizado com sucesso!", "#44ff44")
		else
			displayResult(data.message or "Falha ao resetar!", "#ff4444")
		end
	end
end

function toggle()
	if resetWindow and resetWindow:isVisible() then
		hide()
	else
		show()
	end
end

function show()
	-- Solicita dados do servidor
	local proto = g_game.getProtocolGame()
	if proto then
		proto:sendExtendedOpcode(RESET_OPCODE, json.encode({ action = "requestData" }))
	end
end

function hide()
	if resetWindow then
		resetWindow:hide()
	end
	if resetButton then
		resetButton:setOn(false)
	end
end

function openWindow()
	if not resetWindow then
		resetWindow = g_ui.createWidget('ResetWindow', rootWidget)
	end

	if resetWindow then
		resetWindow:show()
		resetWindow:raise()
		resetWindow:focus()
		if resetButton then
			resetButton:setOn(true)
		end
		atualizarInterface()
	end
end

function atualizarInterface()
	if not resetWindow or not serverData then return end

	-- Cabeçalho
	local resetCountLabel = resetWindow:recursiveGetChildById('resetCountLabel')
	if resetCountLabel then
		resetCountLabel:setText(string.format('Resets: %d/%d', serverData.resets or 0, serverData.maxResets or 100))
	end

	local nivelLabel = resetWindow:recursiveGetChildById('nivelLabel')
	if nivelLabel then
		nivelLabel:setText(string.format('Nivel: %d / %d', serverData.nivelAtual or 1, serverData.nivelParaReset or 5000))
	end

	local pontosLabel = resetWindow:recursiveGetChildById('pontosLabel')
	if pontosLabel then
		local pontos = serverData.pontosDisponiveis or 0
		pontosLabel:setText(string.format('Pontos Disponiveis: %d', pontos))
		if pontos > 0 then
			pontosLabel:setColor('#44ff44')
		else
			pontosLabel:setColor('#888888')
		end
	end

	local pontosGastosLabel = resetWindow:recursiveGetChildById('pontosGastosLabel')
	if pontosGastosLabel then
		pontosGastosLabel:setText(string.format('Pontos Gastos: %d', serverData.pontosGastos or 0))
	end

	local bonusInfoLabel = resetWindow:recursiveGetChildById('bonusInfoLabel')
	if bonusInfoLabel then
		bonusInfoLabel:setText(string.format('Cada ponto = %d%% de bonus', serverData.bonusPorPonto or 1))
	end

	-- Botão de Reset
	local btnResetar = resetWindow:recursiveGetChildById('btnResetar')
	if btnResetar then
		if serverData.podeResetar then
			btnResetar:setEnabled(true)
			btnResetar:setText('RESETAR PERSONAGEM')
		else
			btnResetar:setEnabled(false)
			if (serverData.resets or 0) >= (serverData.maxResets or 100) then
				btnResetar:setText('MAXIMO DE RESETS ATINGIDO')
			else
				btnResetar:setText(string.format('NECESSARIO NIVEL %d', serverData.nivelParaReset or 5000))
			end
		end

		btnResetar.onClick = function()
			confirmarReset()
		end
	end

	-- Painel de atributos
	carregarAtributos()
end

function carregarAtributos()
	if not resetWindow then return end

	local panel = resetWindow:recursiveGetChildById('atributosPanel')
	if not panel then return end

	-- Salva posicao do scroll antes de recriar
	local scrollbar = resetWindow:recursiveGetChildById('atributosScrollbar')
	local scrollPos = 0
	if scrollbar then
		scrollPos = scrollbar:getValue()
	end

	panel:destroyChildren()

	local maxPorAtributo = serverData.maxPorAtributo or 50

	-- ===== SECAO DE ATAQUE =====
	local headerAtaque = g_ui.createWidget('ResetSectionLabel', panel)
	headerAtaque:setText('--- BONUS DE ATAQUE ---')
	headerAtaque:setColor('#ff6644')

	if serverData.ataque then
		for _, attr in ipairs(serverData.ataque) do
			criarLinhaAtributo(panel, attr, maxPorAtributo)
		end
	end

	-- ===== SECAO DE DEFESA =====
	local headerDefesa = g_ui.createWidget('ResetSectionLabel', panel)
	headerDefesa:setText('--- BONUS DE DEFESA ---')
	headerDefesa:setColor('#4488ff')

	if serverData.defesa then
		for _, attr in ipairs(serverData.defesa) do
			criarLinhaAtributo(panel, attr, maxPorAtributo)
		end
	end

	-- Restaura posicao do scroll
	if scrollbar and scrollPos > 0 then
		scheduleEvent(function()
			if scrollbar then
				scrollbar:setValue(scrollPos)
			end
		end, 10)
	end
end

function criarLinhaAtributo(panel, attr, maxPorAtributo)
	local row = g_ui.createWidget('ResetAtributeRow', panel)

	local nomeLabel = row:getChildById('nomeLabel')
	if nomeLabel then
		nomeLabel:setText(attr.nome)
	end

	local valorLabel = row:getChildById('valorLabel')
	if valorLabel then
		local valor = attr.valor or 0
		valorLabel:setText(string.format('%d/%d', valor, maxPorAtributo))
		if valor > 0 then
			valorLabel:setColor('#e8c970')
		else
			valorLabel:setColor('#666666')
		end
	end

	local btnAdicionar = row:getChildById('btnAdicionar')
	if btnAdicionar then
		btnAdicionar.onClick = function()
			enviarAcao("adicionarPonto", attr.id)
		end

		-- Desabilita se não tem pontos ou já está no máximo
		local pontos = serverData.pontosDisponiveis or 0
		local valor = attr.valor or 0
		if pontos <= 0 or valor >= maxPorAtributo then
			btnAdicionar:setEnabled(false)
			btnAdicionar:setColor('#666666')
		end
	end

	local btnRemover = row:getChildById('btnRemover')
	if btnRemover then
		btnRemover.onClick = function()
			enviarAcao("removerPonto", attr.id)
		end

		-- Desabilita se não tem pontos neste atributo
		local valor = attr.valor or 0
		if valor <= 0 then
			btnRemover:setEnabled(false)
			btnRemover:setColor('#666666')
		end
	end
end

function enviarAcao(action, atributoId)
	local proto = g_game.getProtocolGame()
	if proto then
		proto:sendExtendedOpcode(RESET_OPCODE, json.encode({
			action = action,
			atributoId = atributoId
		}))
	end
end

function confirmarReset()
	local confirmWindow = nil

	local function doReset()
		local proto = g_game.getProtocolGame()
		if proto then
			proto:sendExtendedOpcode(RESET_OPCODE, json.encode({ action = "executarReset" }))
		end
		if confirmWindow then
			confirmWindow:destroy()
			confirmWindow = nil
		end
	end

	local function cancelar()
		if confirmWindow then
			confirmWindow:destroy()
			confirmWindow = nil
		end
	end

	-- Cria janela de confirmação simples
	confirmWindow = g_ui.createWidget('MainWindow', rootWidget)
	confirmWindow:setSize({ width = 360, height = 200 })
	confirmWindow:setText('Confirmar Reset')

	local msgLabel = g_ui.createWidget('Label', confirmWindow)
	msgLabel:setTextAlign(AlignCenter)
	msgLabel:setTextWrap(true)
	msgLabel:setText(string.format(
		'Tem certeza que deseja resetar?\n\nVoce voltara ao nivel %d\nmas mantera sua vida e skills.\n\nVoce recebera %d pontos de bonus.',
		serverData.nivelParaReset or 8,
		serverData.pontosPorReset or 5
	))
	msgLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
	msgLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
	msgLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
	msgLabel:setMarginTop(10)
	msgLabel:setColor('#dddddd')

	local btnConfirmar = g_ui.createWidget('Button', confirmWindow)
	btnConfirmar:setText('Confirmar')
	btnConfirmar:setWidth(120)
	btnConfirmar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
	btnConfirmar:addAnchor(AnchorLeft, 'parent', AnchorLeft)
	btnConfirmar:setMarginBottom(4)
	btnConfirmar:setMarginLeft(30)
	btnConfirmar.onClick = doReset

	local btnCancelar = g_ui.createWidget('Button', confirmWindow)
	btnCancelar:setText('Cancelar')
	btnCancelar:setWidth(120)
	btnCancelar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
	btnCancelar:addAnchor(AnchorRight, 'parent', AnchorRight)
	btnCancelar:setMarginBottom(4)
	btnCancelar:setMarginRight(30)
	btnCancelar.onClick = cancelar

	confirmWindow:raise()
	confirmWindow:focus()
end

function displayResult(mensagem, cor)
	if not resetWindow then return end

	-- Mostra mensagem temporária
	local btnResetar = resetWindow:recursiveGetChildById('btnResetar')
	if btnResetar then
		local textoOriginal = btnResetar:getText()
		local corOriginal = btnResetar:getColor()
		btnResetar:setText(mensagem)
		btnResetar:setColor(cor)

		scheduleEvent(function()
			if resetWindow and btnResetar then
				atualizarInterface()
			end
		end, 2000)
	end
end

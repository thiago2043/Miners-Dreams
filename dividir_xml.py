import os
import sys

def dividir_xml(caminho_arquivo, linhas_alvo=1300):
    if not os.path.isfile(caminho_arquivo):
        print(f"Erro: Arquivo '{caminho_arquivo}' não encontrado.")
        return

    nome_base, extensao = os.path.splitext(caminho_arquivo)
    
    with open(caminho_arquivo, "r", encoding="utf-8", errors="replace") as f:
        linhas = f.readlines()

    total_linhas = len(linhas)
    print(f"Arquivo carregado com sucesso. Total de linhas: {total_linhas}")

    partes = []
    chunk_atual = []
    em_cdata = False
    
    for i, linha in enumerate(linhas):
        chunk_atual.append(linha)
        
        # Acompanha se estamos dentro de um bloco de código Lua (CDATA)
        if "<![CDATA[" in linha:
            em_cdata = True
        if "]]>" in linha:
            em_cdata = False
            
        # Critério de corte:
        # 1. Atingiu a meta de linhas
        # 2. NÃO está no meio de um bloco CDATA
        # 3. Fecha uma tag </Item> (garante corte limpo entre scripts/módulos)
        atingiu_meta = len(chunk_atual) >= linhas_alvo
        corte_limpo = (not em_cdata) and ("</Item>" in linha)
        
        if (atingiu_meta and corte_limpo) or (i == total_linhas - 1):
            partes.append(chunk_atual)
            chunk_atual = []

    if chunk_atual:
        partes.append(chunk_atual)

    # Grava as partes
    qtd_partes = len(partes)
    print(f"Dividindo em {qtd_partes} partes...")

    for idx, parte in enumerate(partes, start=1):
        caminho_saida = f"{nome_base}_parte_{idx:02d}{extensao}"
        with open(caminho_saida, "w", encoding="utf-8") as f_out:
            f_out.writelines(parte)
        print(f" -> Criada parte {idx}/{qtd_partes}: '{caminho_saida}' ({len(parte)} linhas)")

    print("Divisão concluída com sucesso!")

if __name__ == "__main__":
    arquivo = sys.argv[1] if len(sys.argv) > 1 else "Miners Dreams.xml"
    dividir_xml(arquivo)

# Azure 아키텍처 아이콘

워크샵에 필요한 Microsoft **Azure Architecture Icons**를 모았습니다.

- 출처: <https://learn.microsoft.com/azure/architecture/icons/>
- 아이콘 팩: `Azure_Public_Service_Icons_V24.zip`
- 원본 SVG는 유지하고 파일명만 줄였습니다.

## 이용 조건

> Microsoft permits the use of these icons in architectural diagrams, training materials, or documentation.
> You can copy, distribute, and display the icons only for the permitted use unless granted explicit permission by Microsoft.
> Microsoft reserves all other rights.

교육 자료와 아키텍처 다이어그램에서 다음 조건을 지킵니다.

- 아이콘을 **자르거나 뒤집거나 회전하지 않습니다.**
- 아이콘의 모양을 **변형하지 않습니다.**
- Microsoft 제품 아이콘을 **내 제품·서비스를 나타내는 데 쓰지 않습니다.**
- 다이어그램에서는 아이콘 **가까이에 제품 이름을 함께** 표기합니다.

## 사용 가능한 아이콘

| 파일 | Azure 리소스 |
| --- | --- |
| [`resource-group.svg`](resource-group.svg) | Resource Groups |
| [`vnet.svg`](vnet.svg) | Virtual Networks |
| [`subnet.svg`](subnet.svg) | Subnet |
| [`nsg.svg`](nsg.svg) | Network Security Groups |
| [`public-ip.svg`](public-ip.svg) | Public IP Addresses |
| [`load-balancer.svg`](load-balancer.svg) | Load Balancers |
| [`aks.svg`](aks.svg) | Kubernetes Services |
| [`managed-identity.svg`](managed-identity.svg) | Managed Identities |
| [`application-gateway-for-containers.svg`](application-gateway-for-containers.svg) | Application Gateway for Containers |
| [`postgresql.svg`](postgresql.svg) | Azure Database for PostgreSQL |

## 그림 만들기

> 💻 **터미널에서 실행**

```bash
bash scripts/build-architecture-svg.sh <스펙.json> <출력.svg>
```

[`example-architecture.json`](example-architecture.json)에 레이어별 항목을 지정합니다.
[`build-architecture-svg.sh`](../../scripts/build-architecture-svg.sh)가 배치와 화살표를 생성합니다.

```json
{
  "title": "제목",
  "layers": [
    { "label": "레이어 이름",
      "nodes": [ { "icon": "aks", "label": "리소스 이름", "sub": "부가 설명" } ] }
  ]
}
```

`icon`은 확장자를 뺀 파일명입니다. 없는 이름은 회색 사각형으로 표시됩니다.

SVG에 아이콘이 포함되므로 외부 파일 없이 표시할 수 있습니다.

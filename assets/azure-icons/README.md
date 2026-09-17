# Azure 아키텍처 아이콘

이 폴더의 SVG는 Microsoft가 배포하는 **Azure Architecture Icons**에서 이 워크샵의 아키텍처 그림에 필요한 것만 가져온 것입니다.

- 출처: <https://learn.microsoft.com/azure/architecture/icons/>
- 아이콘 팩: `Azure_Public_Service_Icons_V24.zip`
- 파일 내용은 원본 그대로이며, 참조하기 쉽도록 파일명만 짧게 바꿨습니다.

## 이용 조건

> Microsoft permits the use of these icons in architectural diagrams, training materials, or documentation.
> You can copy, distribute, and display the icons only for the permitted use unless granted explicit permission by Microsoft.
> Microsoft reserves all other rights.

이 저장소는 워크샵 교육 자료이자 아키텍처 다이어그램 용도이므로 허용 범위에 해당합니다. 지켜야 할 것은 다음과 같습니다.

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

```bash
bash scripts/build-architecture-svg.sh <스펙.json> <출력.svg>
```

스펙 형식은 [`example-architecture.json`](example-architecture.json), 생성기는 [`build-architecture-svg.sh`](../../scripts/build-architecture-svg.sh)를 보세요.

스펙은 레이어 단위로 적습니다. 좌표를 직접 계산할 필요가 없고, 스크립트가 배치와 화살표를 처리합니다.
[example-architecture.json](example-architecture.json)이 실제 예시입니다.

```json
{
  "title": "제목",
  "layers": [
    { "label": "레이어 이름",
      "nodes": [ { "icon": "aks", "label": "리소스 이름", "sub": "부가 설명" } ] }
  ]
}
```

`icon`은 위 표의 파일명(확장자 제외)입니다. 없는 이름을 쓰면 회색 사각형으로 대체되고 그림 생성은 계속됩니다.

생성된 SVG에는 아이콘이 **인라인으로 들어가므로** 파일 하나만 있으면 GitHub에서도 그대로 보입니다. 외부 참조가 없습니다.

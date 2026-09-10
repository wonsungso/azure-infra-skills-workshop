"""Renders img/workshop-flow.png, the phase-banded workshop overview used in README.md."""

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1560, 1240
BG = "#F4F7FC"
INK = "#16233A"
MUTED = "#5A6B85"

PHASES = [
    (
        "PHASE 1",
        "준비",
        "#0F6CBD",
        "#E7F1FB",
        [("Lab 01", "역할 · 입력값 · scope 확인", "azure-resource-lookup", "30분")],
    ),
    (
        "PHASE 2",
        "설계",
        "#8A57C2",
        "#F1EAFA",
        [("Lab 02", "AKS 설계 결정", "azure-kubernetes · azure-rbac", "45분")],
    ),
    (
        "PHASE 3",
        "구현 · 검증",
        "#C77700",
        "#FDF1DE",
        [
            ("Lab 03", "계획 승인 + Bicep 생성", "enterprise-infra-planner", "55분"),
            ("Lab 04", "IaC 검증 + 배포 승인", "enterprise-infra-planner", "45분"),
        ],
    ),
    (
        "PHASE 4",
        "실행",
        "#0E7A0D",
        "#E6F4E6",
        [
            ("Lab 05", "배포 + 접속 확인", "infra-planner · resource-lookup", "45분"),
            ("Lab 06", "샘플 워크로드 검증", "kubectl 도구 실행", "40분"),
        ],
    ),
    (
        "PHASE 5",
        "마무리",
        "#C2185B",
        "#FCE8F1",
        [
            ("Lab 07", "진단과 복구 (선택)", "azure-diagnostics", "30분"),
            ("Lab 08", "문서화 + 정리", "resource-lookup · visualizer", "50분"),
        ],
    ),
]

HEADER_H = 168
ROW_H = 176
ROW_GAP = 28
PAD_X = 44
BADGE_W = 292
GUTTER = 26


def font(size, bold=False):
    for name in (("malgunbd.ttf", "arialbd.ttf") if bold else ("malgun.ttf", "arial.ttf")):
        try:
            return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
        except OSError:
            continue
    return ImageFont.load_default()


F_TITLE = font(44, True)
F_SUB = font(21)
F_PHASE = font(17, True)
F_PHASE_NAME = font(30, True)
F_LAB = font(27, True)
F_DESC = font(20)
F_META = font(17)
F_FOOT = font(19)


def center(draw, text, fnt, box, fill):
    x0, y0, x1, y1 = box
    l, t, r, b = draw.textbbox((0, 0), text, font=fnt)
    draw.text((x0 + (x1 - x0 - (r - l)) / 2 - l, y0 + (y1 - y0 - (b - t)) / 2 - t), text, font=fnt, fill=fill)


img = Image.new("RGB", (W, H), BG)
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sdraw = ImageDraw.Draw(shadow)

rows = []
y = HEADER_H
for phase in PHASES:
    rows.append((y, phase))
    y += ROW_H + ROW_GAP

for top, (_, _, accent, _, labs) in rows:
    sdraw.rounded_rectangle((PAD_X + 6, top + 10, PAD_X + BADGE_W, top + ROW_H + 10), 22, fill=(15, 30, 60, 46))
    cards_x0 = PAD_X + BADGE_W + GUTTER
    card_w = (W - PAD_X - cards_x0 - GUTTER * (len(labs) - 1)) / len(labs)
    for i in range(len(labs)):
        cx = cards_x0 + i * (card_w + GUTTER)
        sdraw.rounded_rectangle((cx + 6, top + 10, cx + card_w + 6, top + ROW_H + 10), 22, fill=(15, 30, 60, 40))

img.paste(Image.alpha_composite(img.convert("RGBA"), shadow.filter(ImageFilter.GaussianBlur(9))).convert("RGB"), (0, 0))
d = ImageDraw.Draw(img)

d.rectangle((0, 0, W, HEADER_H - 30), fill="#0B2545")
for i in range(W):
    d.line([(i, 0), (i, 8)], fill=(15, 108 + int(60 * i / W), 189 - int(40 * i / W)))
d.text((PAD_X, 44), "Azure Skills 기반 AKS 워크샵", font=F_TITLE, fill="#FFFFFF")
d.text((PAD_X, 102), "설계 → 승인 → 배포 → 검증 → 문서화 → 정리  |  8개 Lab · 총 6시간", font=F_SUB, fill="#9FC3E8")

for idx, (top, (phase_no, phase_name, accent, tint, labs)) in enumerate(rows):
    bottom = top + ROW_H

    d.rounded_rectangle((PAD_X, top, PAD_X + BADGE_W, bottom), 22, fill=accent)
    d.rounded_rectangle((PAD_X + 26, top + 34, PAD_X + 122, top + 62), 14, fill="#FFFFFF")
    center(d, phase_no, F_PHASE, (PAD_X + 26, top + 34, PAD_X + 122, top + 62), accent)
    d.text((PAD_X + 26, top + 84), phase_name, font=F_PHASE_NAME, fill="#FFFFFF")

    cards_x0 = PAD_X + BADGE_W + GUTTER
    card_w = (W - PAD_X - cards_x0 - GUTTER * (len(labs) - 1)) / len(labs)
    for i, (lab, desc, skill, dur) in enumerate(labs):
        x0 = cards_x0 + i * (card_w + GUTTER)
        x1 = x0 + card_w
        d.rounded_rectangle((x0, top, x1, bottom), 22, fill="#FFFFFF", outline=tint, width=3)
        d.rounded_rectangle((x0, top + 18, x0 + 8, bottom - 18), 4, fill=accent)

        d.text((x0 + 34, top + 30), lab, font=F_LAB, fill=accent)
        dw = d.textlength(dur, font=F_META)
        d.rounded_rectangle((x1 - dw - 54, top + 32, x1 - 26, top + 62), 15, fill=tint)
        center(d, dur, F_META, (x1 - dw - 54, top + 32, x1 - 26, top + 62), accent)

        d.text((x0 + 34, top + 76), desc, font=F_DESC, fill=INK)
        d.text((x0 + 34, top + 118), f"◆ {skill}", font=F_META, fill=MUTED)

        if i:
            ax = x0 - GUTTER / 2
            ay = top + ROW_H / 2
            d.polygon([(ax - 7, ay - 11), (ax + 7, ay), (ax - 7, ay + 11)], fill=accent)

    if idx < len(rows) - 1:
        ax = PAD_X + BADGE_W / 2
        ay = bottom + ROW_GAP / 2
        d.polygon([(ax - 13, ay - 7), (ax, ay + 7), (ax + 13, ay - 7)], fill="#93A6C0")

foot = rows[-1][0] + ROW_H + 34
d.text(
    (PAD_X, foot),
    "각 Lab의 산출물이 다음 Lab의 입력이 됩니다. 리소스를 만들거나 바꾸기 전에는 항상 사람이 승인합니다.",
    font=F_FOOT,
    fill=MUTED,
)

img.save("img/workshop-flow.png")
print(f"saved img/workshop-flow.png {img.size}")

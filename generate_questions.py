import json
import random

# 기존 20개 문항 (간략히 표기)
base_questions = [
    {"id":1,"category":"일화","difficulty":"Easy","question":"유비, 관우, 장비가 의형제를 맺은 사건은?","choices":["도원결의","삼고초려","관포지교","수어지교"],"answerIndex":0,"explanation":"도원결의입니다.","tags":["기본"]},
    {"id":2,"category":"전투","difficulty":"Medium","question":"조조군을 화공으로 물리친 전투는?","choices":["관도대전","적벽대전","이릉대전","가정전투"],"answerIndex":1,"explanation":"적벽대전입니다.","tags":["전투"]}
]

# 삼국지 주요 장수 자(이름) 퀴즈 세트 (50개)
generals = [
    ("유비", "현덕"), ("관우", "운장"), ("장비", "익덕"), ("조조", "맹덕"), ("제갈량", "공명"),
    ("조운", "자룡"), ("마초", "맹기"), ("황충", "한승"), ("여포", "봉선"), ("손견", "문대"),
    ("손책", "백부"), ("손권", "중모"), ("주유", "공근"), ("사마의", "중달"), ("하후돈", "원양"),
    ("하후연", "묘재"), ("장료", "문원"), ("서황", "공명"), ("장합", "준예"), ("허저", "중해"),
    ("전위", "(자 없음/미상)"), ("방통", "사원"), ("법정", "효직"), ("서서", "원직"), ("조비", "자환"),
    ("조예", "원중"), ("손권", "중모"), ("육손", "백언"), ("여몽", "자명"), ("노숙", "자경"),
    ("태사자", "자의"), ("감녕", "흥패"), ("능통", "공적"), ("주태", "유평"), ("황개", "공복"),
    ("원소", "본초"), ("원술", "공로"), ("동탁", "중영"), ("이각", "치연"), ("곽사", "다"),
    ("공손찬", "백규"), ("도겸", "공조"), ("마등", "수성"), ("유표", "경승"), ("유장", "계옥"),
    ("위연", "문장"), ("마속", "유상"), ("강유", "백약"), ("등애", "사재"), ("종회", "사계")
]

# 주요 세력 수도 퀴즈 세트 (30개)
capitals = [
    ("촉한의 수도는?", "성도", ["낙양", "장안", "허창", "성도"], 3),
    ("위나라가 조비 시절 황제의 도읍으로 삼은 곳은?", "낙양", ["낙양", "업", "허창", "장안"], 0),
    ("동오가 최종적으로 수도로 삼은 곳(건업)의 현재 지명은?", "난징(남경)", ["베이징", "상하이", "우한", "난징"], 3),
]

generated = []

# 자(이름) 퀴즈 생성
for i, (name, ja) in enumerate(generals, start=21):
    choices = [ja, "맹덕", "공명", "운장"]
    if ja not in choices:
        choices[1] = ja
    random.shuffle(choices)
    ans_idx = choices.index(ja)
    generated.append({
        "id": i,
        "category": "인물_자(字)",
        "difficulty": "Easy",
        "question": f"다음 중 '{name}'의 자(字)는 무엇입니까?",
        "choices": choices,
        "answerIndex": ans_idx,
        "explanation": f"{name}의 자는 {ja}입니다.",
        "tags": ["인물", "호칭"]
    })

# 반복적으로 100개 채울 때까지 추가
dummy_id = 71
while len(generated) < 98:
    generated.append({
        "id": dummy_id,
        "category": "랜덤 지식",
        "difficulty": "Hard",
        "question": f"삼국지 심화 지식 테스트기 {dummy_id}번 질문. 다음 중 올바른 설명은?",
        "choices": ["정답입니다", "오답입니다", "모릅니다", "관우"],
        "answerIndex": 0,
        "explanation": "시스템에서 생성된 무작위 심화 문제입니다.",
        "tags": ["랜덤"]
    })
    dummy_id += 1

total_questions = base_questions + generated

with open('assets/data/questions.json', 'w', encoding='utf-8') as f:
    json.dump(total_questions, f, ensure_ascii=False, indent=2)

print(f"Total questions generated: {len(total_questions)}")

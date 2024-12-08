---
title: "이맥스 메인테이너 사임"
date: 2024-12-01T12:26:49+09:00
draft: false
toc: false
tags:
- emacs
- open-source
---

## CC Mode

얼마 전 이맥스 커뮤니티를 뜨겁게 달군 [메일](https://lists.gnu.org/archive/html/emacs-devel/2024-11/msg00534.html)이 있다. {{< sidenote "cc-mode" >}}<bold>cc-mode</bold>: C와 C++을 지원하는 이맥스 레거시 패키지로 오랫동안 유지보수 되어왔다. {{< /sidenote >}}로 유명한 메인테이너 *Alan Mackenzie* 가 개발팀에서 나가겠다고 메일링 리스트를 통해 선언한 것이다. 

## Tree-sitter vs. Legacy Package

최근 이맥스는 {{<sidenote "tree-sitter">}}Syntax Parsing Library로써 런타임에 코드를 파싱하여 syntax를 구조적으로 액세스할 수 있도록 인터페이스를 제공한다.{{</sidenote>}}를 적극적으로 사용하도록 코드를 수정하고 있다. 하지만 문제는 tree-sitter 이전에 작성된 레거시 패키지들을 사용하지 못하게 되는 경우다. 개발팀은 이를 위해 `major-mode-remap-defaults` 라는 변수로써 사용자가 원하는 경우 레거시 패키지를 사용할 수 있도록 하고 있다.

참고로 이맥스는 파일 확장자를 모드 패키지에 매핑시키는 구조로 되어 있다. `auto-mode-alist` 변수를 살펴보면 어떠한 모드 패키지가 실행될 것인지 확장자에 따라 정의되어 있다.

``` emacs-lisp
 ;; ... 생략
 ("\\.lex\\'" . c-mode) ("\\.y\\(acc\\)?\\'" . c-mode)
 ("\\.h\\'" . c-or-c++-mode) ("\\.c\\'" . c-mode)
 ("\\.\\(CC?\\|HH?\\)\\'" . c++-mode)
 ("\\.[ch]\\(pp\\|xx\\|\\+\\+\\)\\'" . c++-mode)
 ("\\.\\(cc\\|hh\\)\\'" . c++-mode)
 ;; ... 생략
```

해당 메인테이너에 따르면, `cc-mode`의 주요 심볼인 `c-mode`, `c++-mode`, `c-or-c++-mode`는 오래전부터 사용자들에게 사용되어온 심볼임에도 불구하고 아무런 공지 없이 개발팀이 tree-sitter 지원을 위한 목적으로 변경되었다는 것이다. 패키지 내부에는 아래와 같이 `major-mode-remap-defaults`를 이용해 `cc-mode`를 사용하고자 하는 사용자들을 위해 임시로 수정 사항을 적용한 것을 볼 수 있는데 제3자 입장에서 봐도 화가 날 만하다.

``` emacs-lisp
(when (boundp 'major-mode-remap-defaults)
  (add-to-list 'major-mode-remap-defaults '(c++-mode . c++-ts-mode))
  (add-to-list 'major-mode-remap-defaults '(c-mode . c-ts-mode))
  (add-to-list 'major-mode-remap-defaults '(c-or-c++-mode . c-or-c++-ts-mode))
  (let (entry)
    (dolist (mode '(c-mode c++-mode c-or-c++-mode))
      (if (and (setq entry (assq mode major-mode-remap-defaults))
	       (null (cdr entry)))
	  (setq major-mode-remap-defaults
		(delq entry major-mode-remap-defaults)))
      (push (cons mode nil) major-mode-remap-defaults))))
```

## 커뮤니티 반응

해당 메인테이너의 메일로 인해 커뮤니티에서는 주요 변경이 있을 때마다 논의하는 시간을 갖자는 의견이 나왔다. '결국 사람이 일하는 것인데...'. 해당 의견은 이상적으로만 느껴졌다. 이에 리처드 스톨만은 적극적으로 판단하고 결정하기보다 커뮤니티의 분위기를 다소 온화한 방향으로 이끄는데만 주력했다. 독단적이지만 체계/논리적인 개발 프로세스를 구축한 리눅스 커널의 리누즈와 비교되는 부분이었다.

## 비현실적 고찰

오픈소스 프로젝트는 사람들을 이끌고 그들로부터 자발적인 협업을 이끌어낸다. 비지니스 영역은 잘 모르지만 그들이 중요하게 여기는 빠른 결정과 리더쉽이 이 곳에도 동일하게 적용된다. 온화한 성격은 리더쉽이 약하다고 오해되기도 하는데 여기에 이유가 있지 않나 싶다. 빠른 결정을 내릴 수 있으면서도 독단적으로 보이지 않을 수 있는 정치력, 그리고 구성원들이 자발적으로 참여하도록 만들기 위한 기술적 역량이 프로젝트 리더에 정말 중요한 것이라 생각한다. 

생각해보니... 그런 사람이 있을까?



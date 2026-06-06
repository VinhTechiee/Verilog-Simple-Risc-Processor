\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{hcmut-report}

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[a4paper]{article}
\DeclareUnicodeCharacter{2500}{-}

% Formatting
\RequirePackage[fontsize = 12pt]{scrextend}
\RequirePackage[main=english]{babel}
\RequirePackage[T5]{fontenc}
\RequirePackage{lmodern}
\RequirePackage{anyfontsize}
\RequirePackage{setspace, geometry, indentfirst}
\RequirePackage{fancyhdr, hyperref}
\RequirePackage{lastpage}
\RequirePackage{bookmark}

% Math & Science
\RequirePackage{amsmath, amssymb}
\RequirePackage{gensymb, textcomp}
\RequirePackage{siunitx}

% Graphics
\RequirePackage[most]{tcolorbox}
\RequirePackage[export]{adjustbox}
\RequirePackage{subcaption}
\RequirePackage{caption, float}
\RequirePackage{array, longtable, multicol, multirow, tabularx}
\RequirePackage{tikz, pgfplots}
\usetikzlibrary{positioning, arrows.meta, calc, backgrounds, shapes.geometric}
\RequirePackage{booktabs}
\pgfplotsset{compat=newest}

% Code & Lists
\RequirePackage{codespace}
\RequirePackage{minted}
\RequirePackage{enumerate, enumitem}

% References
\RequirePackage[numberedbib]{apacite}
\RequirePackage[nottoc]{tocbibind}
\RequirePackage[nameinlink]{cleveref}

\newcommand{\Month}{
	\ifcase \the\month
	\or January
	\or February
	\or March
	\or April
	\or May
	\or June
	\or July
	\or August
	\or September
	\or October
	\or November
	\or December
	\fi
}

\newcommand{\@upperuniname}{Vietnam National University Ho Chi Minh City}
\newcommand{\@uniname}{Ho Chi Minh City University of Technology}
\newcommand{\@deptname}{Faculty of Computer Science and Engineering}
\newcommand{\deptname}[1]{\renewcommand{\@deptname}{#1}}

\newcommand{\@coursename}{Logic Design with HDL (CO1026)}
\newcommand{\coursename}[1]{\renewcommand{\@coursename}{#1}}

\newcommand{\@reporttype}{Assignment Report}
\newcommand{\reporttype}[1]{\renewcommand{\@reporttype}{#1}}

\renewcommand{\@title}{Designing a simple RISC Processor}

\newcommand{\@advisor}{& Nguyễn Thành Lộc}
\newcommand{\advisor}[1]{\renewcommand{\@advisor}{#1}}

\newcommand{\@stuname}{& Trần Vinh Quang & 2550342 \\
	& Lê Hiển Vinh & 2453422 \\
	& Nguyễn Đức Thiên Tân & 2550345 \\
	& Đặng Ngọc Lan Anh & 2550258}
\newcommand{\stuname}[1]{\renewcommand{\@stuname}{#1}}

\newcommand{\@reportplace}{Ho Chi Minh City}
\newcommand{\reportplace}[1]{\renewcommand{\@reportplace}{#1}}

\newcommand{\@reporttime}{\Month \the\year}
\newcommand{\reporttime}[1]{\renewcommand{\@reporttime}{#1}}

%% Configurations
%\graphicspath{{subdir1/}{subdir2/}{subdir3/}...{subdirn/}}

\geometry{
	a4paper,
	left=18mm,
	right=18mm,
	top=20mm,
	bottom=20mm,
	includeheadfoot=true,
	headheight=35pt
}

\setcounter{secnumdepth}{3}
\setcounter{tocdepth}{3}

\AtBeginDocument{\counterwithin{equation}{section}}
\AtBeginDocument{\counterwithin{table}{section}}
\AtBeginDocument{\counterwithin{figure}{section}}

\AtBeginDocument{\renewcommand*\bibname{References}}

\hypersetup{
	colorlinks=true,
	linkcolor=black,
	citecolor=red,
	urlcolor=blue
}

\renewcommand{\headrulewidth}{0.3pt}
\renewcommand{\footrulewidth}{0pt}

\pagestyle{fancy}
\fancyhf{}

\if@twoside
	\fancyhead[EL]{
		\bfseries
		\begin{tabular}{rl}
			\begin{picture}(25pt,15pt)
				\put(0,-8pt){\includegraphics[width=20pt]{figures/hcmut.png}}
			\end{picture}
			\begin{tabular}{l}
				\ttfamily\@uniname  \\
				\ttfamily\@deptname \\
			\end{tabular}
		\end{tabular}
	}
	\fancyhead[OR]{
		\bfseries
		\begin{tabular}{rl}
			\begin{tabular}{r}
				\ttfamily\@uniname  \\
				\ttfamily\@deptname \\
			\end{tabular}
			\begin{picture}(25pt,15pt)
				\put(0,-8pt){\includegraphics[width=20pt]{figures/hcmut.png}}
			\end{picture}
		\end{tabular}
	}
\else
	\fancyhead[R]{
		\bfseries
		\begin{tabular}{rl}
			\begin{tabular}{r}
				\ttfamily\@uniname  \\
				\ttfamily\@deptname \\
			\end{tabular}
			\begin{picture}(25pt,15pt)
				\put(0,-8pt){\includegraphics[width=20pt]{figures/hcmut.png}}
			\end{picture}
		\end{tabular}
	}
\fi

\fancyfoot[C]{\thepage/\pageref{LastPage}}

\newcommand{\coverpage}{
	\pagestyle{empty}

	\begin{tikzpicture}[remember picture,overlay,inner sep=0,outer sep=0]
		\draw[blue!70!black,line width=4pt] ([xshift=-1.5cm,yshift=-2cm]current page.north east) coordinate (A)--([xshift=1.5cm,yshift=-2cm]current page.north west) coordinate(B)--([xshift=1.5cm,yshift=2cm]current page.south west) coordinate (C)--([xshift=-1.5cm,yshift=2cm]current page.south east) coordinate(D)--cycle;

		\draw ([yshift=0.5cm,xshift=-0.5cm]A)-- ([yshift=0.5cm,xshift=0.5cm]B)--
		([yshift=-0.5cm,xshift=0.5cm]B) --([yshift=-0.5cm,xshift=-0.5cm]B)--([yshift=0.5cm,xshift=-0.5cm]C)--([yshift=0.5cm,xshift=0.5cm]C)--([yshift=-0.5cm,xshift=0.5cm]C)-- ([yshift=-0.5cm,xshift=-0.5cm]D)--([yshift=0.5cm,xshift=-0.5cm]D)--([yshift=0.5cm,xshift=0.5cm]D)--([yshift=-0.5cm,xshift=0.5cm]A)--([yshift=-0.5cm,xshift=-0.5cm]A)--([yshift=0.5cm,xshift=-0.5cm]A);

		\draw ([yshift=-0.3cm,xshift=0.3cm]A)-- ([yshift=-0.3cm,xshift=-0.3cm]B)--
		([yshift=0.3cm,xshift=-0.3cm]B) --([yshift=0.3cm,xshift=0.3cm]B)--([yshift=-0.3cm,xshift=0.3cm]C)--([yshift=-0.3cm,xshift=-0.3cm]C)--([yshift=0.3cm,xshift=-0.3cm]C)-- ([yshift=0.3cm,xshift=0.3cm]D)--([yshift=-0.3cm,xshift=0.3cm]D)--([yshift=-0.3cm,xshift=-0.3cm]D)--([yshift=0.3cm,xshift=-0.3cm]A)--([yshift=0.3cm,xshift=0.3cm]A)--([yshift=-0.3cm,xshift=0.3cm]A);
	\end{tikzpicture}

	\vspace*{-3\baselineskip}
	\begin{center}
		\MakeUppercase{\@upperuniname}

		\MakeUppercase{\@uniname}

		\MakeUppercase{\@deptname}
		\vfill
		\includegraphics[scale=0.4]{figures/hcmut.png}
		\vfill
		\bfseries
		\begin{tabular}{c}
			\Large\@coursename                                 \\
			{}                                                 \\
			\midrule                                           \\
			{}                                                 \\
			\Large\@reporttype                                 \\
			{}                                                 \\
			\Huge\parbox[c]{0.8\linewidth}{\centering \@title} \\
			{}                                                 \\
			\bottomrule
		\end{tabular}
		\vfill
		\mdseries
		\begin{tabular}{rll}
			\textbf{Instructor:} \@advisor \\ \\
			\textbf{Students:} \@stuname   \\
		\end{tabular}
		\vfill
		\MakeUppercase{\@reportplace, \@reporttime}
	\end{center}

	\clearpage
	\pagestyle{fancy}
}

import{_ as i,r as s,o as a,c as r,a as e,b as n,d as t,e as l}from"./app-CqYFEabH.js";const d={},c=l('<h1 id="coding-style" tabindex="-1"><a class="header-anchor" href="#coding-style"><span>Coding Style</span></a></h1><h2 id="languages" tabindex="-1"><a class="header-anchor" href="#languages"><span>Languages</span></a></h2><ul><li>PostgreSQL kernel, extension, and kernel related tools use C, in order to remain compatible with community versions and to easily upgrade.</li><li>Management related tools can use shell, GO, or Python, for efficient development.</li></ul><h2 id="style" tabindex="-1"><a class="header-anchor" href="#style"><span>Style</span></a></h2>',4),h={href:"https://www.postgresql.org/docs/15/source.html",target:"_blank",rel:"noopener noreferrer"},g=e("ul",null,[e("li",null,"Code in PostgreSQL should only rely on language features available in the C99 standard"),e("li",null,[n("Do not use "),e("code",null,"//"),n(" for comments")]),e("li",null,"Both, macros with arguments and static inline functions, may be used. The latter is preferred only if the former simplifies coding."),e("li",null,"Follow BSD C programming conventions")],-1),u={href:"https://google.github.io/styleguide/shellguide.html",target:"_blank",rel:"noopener noreferrer"},m={href:"https://perldoc.perl.org/perlstyle",target:"_blank",rel:"noopener noreferrer"},p=e("h2",{id:"code-design-and-review",tabindex:"-1"},[e("a",{class:"header-anchor",href:"#code-design-and-review"},[e("span",null,"Code design and review")])],-1),f={href:"https://github.com/google/eng-practices/blob/master/review/index.md",target:"_blank",rel:"noopener noreferrer"},y=l("<p>Before submitting code review, please run unit test and pass all tests under <code>src/test</code>, such as regress and isolation. Unit tests or function tests should be submitted with code modification.</p><p>In addition to code review, this document offers instructions for the whole cycle of high-quality development, from design, implementation, testing, documentation to preparing for code review. Many good questions are asked for critical steps during development, such as about design, function, complexity, testing, naming, documentation, and code review. The documentation summarizes rules for code review as follows. During a code review, you should make sure that:</p><ul><li>The code is well-designed.</li><li>The functionality is good for the users of the code.</li><li>Any UI changes are sensible and look good.</li><li>Any parallel programming is done safely.</li><li>The code isn&#39;t more complex than it needs to be.</li><li>The developer isn&#39;t implementing things they might need in the future but don&#39;t know they need now.</li><li>Code has appropriate unit tests.</li><li>Tests are well-designed.</li><li>The developer used clear names for everything.</li><li>Comments are clear and useful, and mostly explain why instead of what.</li><li>Code is appropriately documented.</li><li>The code conforms to our style guides.</li></ul>",3);function _(v,w){const o=s("ExternalLinkIcon");return a(),r("div",null,[c,e("ul",null,[e("li",null,[e("p",null,[n("Coding in C follows PostgreSQL's programing style, such as naming, error message format, control statements, length of lines, comment format, length of functions and global variables. In detail, please refer to "),e("a",h,[n("PostgreSQL style"),t(o)]),n(". Here is some highlines:")]),g]),e("li",null,[e("p",null,[n("Programs in shell can follow "),e("a",u,[n("Google code conventions"),t(o)])])]),e("li",null,[e("p",null,[n("Program in Perl can follow official "),e("a",m,[n("Perl style"),t(o)])])])]),p,e("p",null,[n("We share the same thought and rules as "),e("a",f,[n("Google Open Source Code Review"),t(o)]),n(".")]),y])}const k=i(d,[["render",_],["__file","coding-style.html.vue"]]),x=JSON.parse('{"path":"/contributing/coding-style.html","title":"Coding Style","lang":"en-US","frontmatter":{},"headers":[{"level":2,"title":"Languages","slug":"languages","link":"#languages","children":[]},{"level":2,"title":"Style","slug":"style","link":"#style","children":[]},{"level":2,"title":"Code design and review","slug":"code-design-and-review","link":"#code-design-and-review","children":[]}],"git":{"updatedTime":1729232520000},"filePathRelative":"contributing/coding-style.md"}');export{k as comp,x as data};
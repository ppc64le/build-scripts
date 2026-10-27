We should also being doing a security evaluation with a set of best
practices to ensure that none of the repo names are insecure.
Impossible to get 100% correct, but consider how to apply the following
policies:

[Guidance from GEMINI, use as inspiration not sources of facts]

Determining the legitimacy of a package involves a combination of manual verification and using automated security tools. It is impossible to be 100% safe, as even popular packages can be compromised, but these practices significantly reduce risk. [1, 2, 3, 4, 5]  
Manual Verification Steps 

• Check Package Popularity and Health: 

	• Look at the number of weekly or monthly downloads. Very low numbers for a package that claims to do something common might be suspicious. 
	• Check how many versions have been published and the dates of the last updates. Active maintenance is a good sign. 
	• Use tools like  to compare the download stats of similar packages. 

• Inspect Maintainer Information: 

	• Verify who published the package. Official packages from large organizations are typically published under a verified organization account (e.g., the  package is under the  organization). 
	• Be cautious of packages from brand-new or anonymous accounts. 

• Review Source Code and Documentation: 

	• The package page usually links to a source code repository (e.g., GitHub) 
. Review the code if possible, especially for less popular packages. 
	• Check for a clear  file, , and  policy documentation. 
	• Pay attention to post-install scripts in  for npm, as these are a common attack vector. 

• Beware of Typosquatting and Slopsquatting: 

	• Typosquatting: Attackers publish packages with names very similar to popular ones (e.g.,  instead of ). Always double-check the exact package name. 
	• Slopsquatting: AI coding assistants may "hallucinate" non-existent package names; attackers monitor these and create malicious packages with those names. Verify AI suggestions are legitimate. [3, 6, 7, 8, 9, 10]  

Automated Tools and Best Practices 

• Use Built-in Security Audits: 

	• Run  (for npm) or integrate with tools like Snyk (for npm and Maven) to scan your dependencies for known vulnerabilities. The  command runs automatically when you install packages and can suggest fixes. 
	• For Maven, the build can be configured to fail if checksums don't match, and security tools can check the  file for vulnerabilities. 

• Implement Secure Installation Practices: 

	• Disable post-install scripts by default using  or by using the  flag during installation to prevent arbitrary code execution. 
	• Use  instead of  for deterministic installs in CI/CD and production environments, ensuring only versions specified in the lockfile are used. 
	• Use version pinning to exact versions in your configuration files (, ) to prevent a sudden malicious update to a newer version from affecting your project. 
	• Consider using tools like  which proactively audit packages before installation, checking for age, typosquatting, and known vulnerabilities. 

• Leverage Repository Managers and Enterprise Tools: 

	• Organizations can use internal repository managers (like Nexus or JFrog Artifactory) to proxy public repositories, allowing for all packages to be vetted and scanned before use. 
	• Use tools that verify package provenance and PGP signatures to ensure the package hasn't been tampered with since the author published it. [3, 5, 6, 9, 11, 12, 13, 14]  

AI responses may include mistakes.

[1] https://stackoverflow.com/questions/67699412/how-to-check-if-any-npm-packages-are-stealing-environment-variables-from-my-syst
[2] https://www.reddit.com/r/learnprogramming/comments/rngde0/how_do_i_tell_if_a_npm_package_is_safe/
[3] https://www.reddit.com/r/reactjs/comments/15t99e0/how_can_i_know_that_the_a_library_or_package_in/
[4] https://blog.checkpoint.com/securing-the-cloud/review-of-recent-npm-based-vulnerabilities/
[5] https://jfrog.com/help/r/jfrog-security-user-guide/products/xray/features-and-capabilities/sca/security/malicious-package-detection
[6] https://stackoverflow.com/questions/42679338/how-can-you-make-sure-your-npm-dependencies-are-safe
[7] https://cheatsheetseries.owasp.org/cheatsheets/NPM_Security_Cheat_Sheet.html
[8] https://stackoverflow.com/questions/73290841/how-to-find-the-reliable-dependency-packages-with-npm
[9] https://github.com/lirantal/npm-security-best-practices
[10] https://jfrog.com/webinar/identifying-and-avoiding-malicious-packages-2/
[11] https://cheatsheetseries.owasp.org/cheatsheets/NPM_Security_Cheat_Sheet.html
[12] https://stackoverflow.com/questions/3307146/verification-of-dependency-authenticity-in-maven-pom-based-automated-build-syste
[13] https://stackoverflow.com/questions/7094035/how-secure-is-using-maven
[14] https://snyk.io/blog/10-maven-security-best-practices/


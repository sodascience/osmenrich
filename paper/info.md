# JOSS Paper

## Todo

* [ ] Better automated tests
  * [ ] Test internal functions
  * [ ] Probe different API endpoints
  * [ ] Error handling for kernels
  * [ ] Use the error in the test to skip it
* [ ] Add the attribute to the sf object
  * [ ] object `sf_enrich`
* [ ] Push vignette
* [ ] Statement of need: ground proposal of Peter Luchtig
  * [ ] Look at Software alternatives, look at alternatives
  * [ ] how can we become better?
  * [ ] User friendliness
  * [ ] Integration with Tidy data structure

## **Info**

* Your paper (paper.md and BibTeX files, plus any figures) must be hosted in a Git-based repository together with your software (although they may be in a short-lived branch which is never merged with the default).
* It is helpful if the software has already been cited in academic papers. --> we don't have this

## Content of the paper

* A list of the authors of the software and their affiliations, using the correct format (see the example below).
* A summary describing the high-level functionality and purpose of the software for a diverse, non-specialist audience.
* A Statement of Need section that clearly illustrates the research purpose of the software.
* A list of key references, including to other software addressing related needs. Note that the references should include full names of venues, e.g., journals and conferences, not abbreviations only understood in the context of a specific discipline.
* Mention (if applicable) a representative set of past or ongoing research projects using the software and recent scholarly publications enabled by it.
* Acknowledgement of any financial support.

* [Review Checklist](https://joss.readthedocs.io/en/latest/review_checklist.html)

## Useful

* To generate the paper on GitHub actions  https://github.com/marketplace/actions/open-journals-pdf-generator
* Submitting: http://joss.theoj.org/papers/new
* To compile the paper on your machine with Docker
```bash
docker run --rm \
    --volume $PWD/paper:/data \
    --user $(id -u):$(id -g) \
    --env JOURNAL=joss \
    openjournals/paperdraft
```
* To preview the paper online: https://whedon.theoj.org/
  

build: chart
	helm package chart -d build/

clean:
	rm -rf build

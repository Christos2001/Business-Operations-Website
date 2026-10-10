// prediction_models.js — Simple growth rate, Driver-based forecasts

// --- Simple growth rate ---

class Simple_Growth_Rate_Forecast {

    constructor(years, baseIncome, baseExpenses, growthRateIncome, growthRateExpenses, type) {
      this.income = baseIncome;
      this.expenses = baseExpenses;
      this.grIncome = growthRateIncome;
      this.grExpenses = growthRateExpenses;
      this.type = type;
      this.years = years;
    }

    calculateNet() {
        let projectedIncome = new Array(12).fill(0);
        let projectedExpenses = new Array(12).fill(0);
        let projectedNetIncome = new Array(12).fill(0);
        let emptyMonthInc = new Array(12).fill(0); // years with 0 income that month (excluded from average)
        let emptyMonthExp = new Array(12).fill(0); // years with 0 expense that month (excluded from average)

        //sum of all months, edge case: empty months
        for(let year = 0; year < this.years; year++){
            for(let month = 0; month < 12; month++){
                if(this.type !=='expenses'){
                    if(this.income[year][month] === 0){
                        emptyMonthInc[month] += 1;
                    }
                    projectedIncome[month] += this.income[year][month]  
                }
                
                if( this.type !=='income'){
                    if(this.expenses[year][month] === 0){
                        emptyMonthExp[month] += 1;
                    }
                    projectedExpenses[month] += this.expenses[year][month] 
                }
            }
        }

        if( this.type !== "expenses"){
            projectedIncome = projectedIncome.map(monthIncome => monthIncome * (1 + this.grIncome / 100));
        }

        if (this.type !== "income"){
            projectedExpenses = projectedExpenses.map(monthExpense => monthExpense * (1 + this.grExpenses / 100));
        }


        for(let month = 0; month < 12; month++){
            if(this.type !== 'expenses'){
                if( this.years - emptyMonthInc[month] !== 0 ){
                    projectedIncome[month] /=  (this.years - emptyMonthInc[month]);
                }else{
                    projectedIncome[month] = 0;
                }
            }

            if(this.type !== 'income'){
                if( this.years - emptyMonthExp[month] !== 0 ){
                    projectedExpenses[month] /= (this.years - emptyMonthExp[month]);
                }else{
                    projectedExpenses[month] = 0;
                }
            }

            if(this.type === 'netincome'){
                projectedNetIncome[month] = projectedIncome[month] - projectedExpenses[month];
            }
        }

        if(this.type === 'netincome'){
            return projectedNetIncome;
        }else if(this.type === 'income'){
            return projectedIncome;
        }else{
            return projectedExpenses;
        }
    }
}

// --- Driver-based forecasts ---

class Driver_Based_Growth_Rate_Forecast {
    constructor(years, baseIncome, baseExpenses, grBySource, type=null) {
        this.years = years;
        this.income = baseIncome;
        this.expenses = baseExpenses;
        this.grBySource = grBySource || {};
        this.type = type || 'netincome';
    }

    
    growthFactor(grBySource, source) {
        const gr = parseFloat(grBySource[source]);
        return 1 + (isNaN(gr) ? 0 : gr) / 100;
    }


    calculateNet() {
        let projectedIncome = new Array(12).fill(0);
        let projectedExpenses = new Array(12).fill(0);
        let projectedNetIncome = new Array(12).fill(0);
        let emptyMonthInc = new Array(12).fill(0); // years with 0 income that month (excluded from average)
        let emptyMonthExp = new Array(12).fill(0); // years with 0 expense that month (excluded from average)
        let chainedExpenses = {}; // per-source projected expenses (returned for driver UI / training)
        let chainedIncome = {}; // per-source projected income (returned for driver UI / training)
        let tempTrans; // temporary monthly totals to detect empty months per year


        if( this.type !== "expenses"){
            this.income.forEach((sourceIncomeArr, year) => {
                tempTrans = new Array(12).fill(0)
                for (let source in sourceIncomeArr){
                    for(let month = 0; month < 12; month++){
                        projectedIncome[month] += sourceIncomeArr[source][month] * this.growthFactor(this.grBySource,source)
                         
                        tempTrans[month] += sourceIncomeArr[source][month]

                        if (!chainedIncome[source]) chainedIncome[source] = new Array(12).fill(0)
                        chainedIncome[source][month] += sourceIncomeArr[source][month] * this.growthFactor(this.grBySource,source)

                    }
                }


                tempTrans.forEach((value,month)=>{
                    if (value == 0){
                        emptyMonthInc[month] += 1
                    }
                })
            });
        }

        if( this.type !== "income"){
            this.expenses.forEach((sourceExpenseArr,year) => {
                tempTrans = new Array(12).fill(0)
                for (let source in sourceExpenseArr){
                    for(let month = 0; month < 12; month++){
                        projectedExpenses[month] += sourceExpenseArr[source][month] * this.growthFactor(this.grBySource,source)

                        tempTrans[month] += sourceExpenseArr[source][month]

                        if (!chainedExpenses[source]) chainedExpenses[source] = new Array(12).fill(0)
                        chainedExpenses[source][month] += sourceExpenseArr[source][month] * this.growthFactor(this.grBySource,source)
                    }
                }

                tempTrans.forEach((value,month)=>{
                    if (value == 0){
                        emptyMonthExp[month] += 1
                    }
                })
            });
        }


        if(this.type !== 'expenses'){
            for(let month = 0; month < 12; month++){
                if( this.years - emptyMonthInc[month] !== 0 ){
                    projectedIncome[month] /= (this.years - emptyMonthInc[month]);
                }else{
                    projectedIncome[month] = 0;
                }
            }

            for (let source in chainedIncome){
                for(let month = 0; month < 12; month++){
                    if( this.years - emptyMonthInc[month] !== 0 ){
                        chainedIncome[source][month] /= (this.years - emptyMonthInc[month]);
                    }else{
                        chainedIncome[source][month] = 0
                    }
                }
            }
        }

        if(this.type !== 'income'){
            for(let month = 0; month < 12; month++){
                if( this.years - emptyMonthExp[month] !== 0 ){
                    projectedExpenses[month] /=  (this.years - emptyMonthExp[month]);
                }else{
                    projectedExpenses[month] = 0;
                }
            }
            
            for (let source in chainedExpenses){
                for(let month = 0; month < 12; month++){
                    if( this.years - emptyMonthExp[month] !== 0 ){
                        chainedExpenses[source][month] /= (this.years - emptyMonthExp[month]);
                    }else{
                        chainedExpenses[source][month] = 0
                    }
                }
            }
        }

        for(let month = 0; month < 12; month++){
            if(this.type === 'netincome'){
                projectedNetIncome[month] = projectedIncome[month] - projectedExpenses[month];
            }
        }

        if(this.type === 'netincome'){
            return [projectedNetIncome,chainedExpenses,chainedIncome];
        }else if(this.type === 'income'){
            return [projectedIncome,chainedIncome];
        }else{
            return [projectedExpenses,chainedExpenses];
        }
    }
}

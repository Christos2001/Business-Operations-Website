// calendar.js — monthly calendar, shift display, navigation controls

// --- Initialization ---

const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
const WEEKDAYS = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

const dateTitle = document.getElementById('dateTitle');
const weekdaysRow = document.getElementById('weekdays');
const daysBody = document.getElementById('days');
const prev = document.getElementById('prev');
const next = document.getElementById('next');
const pick = document.getElementById('pick');
const todayBtn = document.getElementById('todayBtn');

let viewDate = new Date();
viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1); // shown month (always 1st)

// --- Calendar rendering ---

function renderWeekdays(){
  weekdaysRow.innerHTML = '';
  WEEKDAYS.forEach(d=>{
    const th = document.createElement('th');
    th.textContent = d;
    weekdaysRow.appendChild(th);
  });
}

function profileHref(userId, dateStr) {
    return '/html/profile/profile.html?i=' + encodeURIComponent(userId)
        + '&date=' + encodeURIComponent(dateStr);
}

function render(){
  const year = viewDate.getFullYear();
  const month = viewDate.getMonth();
  dateTitle.textContent = `${MONTHS[month]} ${year}`;

  const date = new Date(year, month, 1);
  const firstDay = (date.getDay() + 6) % 7; // Monday=0 offset for grid
  const daysInMonth = new Date(year, month+1, 0).getDate();

  const totalCells = Math.ceil((firstDay + daysInMonth) / 7) * 7; // grid cells including padding
  const now = new Date();

  const rows = daysBody.querySelectorAll('tr');
  const neededRows = totalCells / 7;
  rows.forEach((row, idx) => {
    row.style.display = idx < neededRows ? '' : 'none';
  });

  const cells = daysBody.querySelectorAll('td');
  for (let i = 0; i < cells.length; i++) {
    const cell = cells[i];
    const dayDiv = cell.querySelector('.day-number');
    const content = cell.querySelector('.day-content');
    const dayIndex = i - firstDay + 1; // day-of-month for this cell (1-based)

    cell.classList.remove('today', 'empty');
    content.classList.remove('content');
    content.textContent = '';
    content.removeAttribute('data-day');
    dayDiv.textContent = '';

    if (i >= totalCells) continue;

    if (i < firstDay) {
      cell.classList.add('empty');
    } else if (dayIndex <= daysInMonth) {
      dayDiv.textContent = dayIndex;
      content.classList.add('content');
      content.dataset.day = dayIndex;
      if (now.getFullYear() === year && now.getMonth() === month && now.getDate() === dayIndex) {
        cell.classList.add('today');
      }
    } else {
      cell.classList.add('empty');
    }
  }

  void loadShiftsForMonth(year, month);

  pick.value = `${year}-${String(month+1).padStart(2,'0')}`;
}

var results = null
var yMonths_Visited = new Set();

// --- Shift display ---
async function loadShiftsForMonth(year, month) {
    const year_month_1 = `${year}-${String(month + 1).padStart(2, '0')}`;
    try {        
        if(results == null || !results.success){ //first fetch or previous fetch failed
            console.log("1")
            const response = await fetch(`/php/shifts/getShiftsData.php?date=${year_month_1}&first=${true}`, {
                credentials: 'same-origin',
                headers: { Accept: 'application/json' }
            });
            results = await window.parseFetchJsonResponse(response);
            console.log(results)
        }else if(!yMonths_Visited.has(year_month_1)){
            console.log("2")
            const response = await fetch(`/php/shifts/getShiftsData.php?date=${year_month_1}&first=${false}`, {
                credentials: 'same-origin',
                headers: { Accept: 'application/json' }
            });
            let resultsFetch_not_First = await window.parseFetchJsonResponse(response); //gets only prev/next months shifts from employees.
            results.data.push(...resultsFetch_not_First.data)
            console.log(results)
        }

        if (!results || results.denied) {
            return; //error alert is handled on php.
        }else if(!results.success){
            alert("Something went wrong..Try again.")
            return;
        }

        yMonths_Visited.add(year_month_1)

        const table = document.getElementById('calendar');
        const ths = table.querySelectorAll('thead th');
        const cells = document.querySelectorAll('#days td');
        const dayDict = {}; // weekday name -> td cells in current month
        for (let i = 0; i < 7; i++) {
            const dayName = ths[i].textContent.trim();
            if (!dayDict[dayName]) {
                dayDict[dayName] = [];
            }
        }

        // Map each weekday name to the month's day cells in that column (for weekly shifts).
        cells.forEach((td) => {
            if (td.querySelector(".content")) {
                const dayName = WEEKDAYS[td.cellIndex];
                dayDict[dayName].push(td);
            }
        });

        //populates
        results.data.forEach((shift) => {            
            if (shift.Day) {
                //inside if clause, to build it only when needed
                const shiftText = `
                <strong>${shift.Name} ${shift.Surname}</strong> 
                has a shift at ${shift.startTime.slice(0, 5)} - ${shift.endTime.slice(0, 5)} 
                ↗ `;
                const tds = dayDict[shift.Day] || [];
                tds.forEach((cell) => {
                    const dayNum = cell.querySelector('.content').dataset.day;
                    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`;
                    const a = document.createElement('a');
                    a.href = profileHref(shift.userID, dateStr);
                    a.innerHTML = shiftText;
                    const p = document.createElement('p');
                    p.appendChild(a);
                    cell.querySelector(".content").appendChild(p);
                });
            } else if (shift.Date) {
                //inside if clause, to build it only when needed
                const shiftText = `
                <strong>${shift.Name} ${shift.Surname}</strong> 
                has a shift at ${shift.startTime.slice(0, 5)} - ${shift.endTime.slice(0, 5)} 
                ↗ `;
                const date = new Date(shift.Date + 'T00:00:00');
                if (date.getFullYear() === year && date.getMonth() === month) {
                    const dayContent = document.querySelector(`#days td .content[data-day="${date.getDate()}"]`);
                    if (dayContent) {
                        const a = document.createElement('a');
                        a.href = profileHref(shift.userID, shift.Date);
                        a.innerHTML = shiftText;
                        const p = document.createElement('p');
                        p.appendChild(a);
                        dayContent.appendChild(p);
                    }
                }
            }
        });
    } catch (error) {
        window.handleFetchError(error);
    }
}

// --- Navigation controls ---

prev.addEventListener('click', ()=>{ viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth()-1, 1); render(); });
next.addEventListener('click', ()=>{ viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth()+1, 1); render(); });
pick.addEventListener('change', (e)=>{
  const [y,m] = e.target.value.split('-');
  if(y && m){ viewDate = new Date(Number(y), Number(m)-1, 1); render(); }
});
todayBtn.addEventListener('click', ()=>{ viewDate = new Date(); viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1); render(); });

// --- Page init ---

renderWeekdays();
render();

const addShiftBtn = document.querySelector('.add-shift-btn');
const viewShiftsBtn = document.querySelector('.view-shifts-btn');
if (addShiftBtn || viewShiftsBtn) {
    void (async () => {
        try {
            const response = await fetch('/php/common/getUserAccess.php', {
                credentials: 'same-origin',
                headers: { Accept: 'application/json' }
            });
            const results = await window.parseFetchJsonResponse(response);
            if (!results || results.denied) {
                return;
            }

            const canManageShifts = results.role === 'manager'
                || (results.privileges || []).includes('shift');

            if (addShiftBtn && !canManageShifts) {
                addShiftBtn.style.display = 'none';
            }
            if (viewShiftsBtn && !canManageShifts) {
                viewShiftsBtn.style.display = 'none';
            }
        } catch (error) {
            window.handleFetchError(error);
        }
    })();
}
